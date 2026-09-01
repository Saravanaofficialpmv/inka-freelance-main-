import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/client.dart';
import '../../data/models/invoice.dart';
import '../../data/models/invoice_item.dart';
import '../../data/models/time_entry.dart';
import '../../services/firestore_service.dart';
import 'invoice_viewmodel.dart';

// ==================== TIME ENTRIES NOTIFIER ====================

class TimeEntriesNotifier extends StateNotifier<List<TimeEntry>> {
  final FirestoreService _firestoreService;

  TimeEntriesNotifier(this._firestoreService) : super([]) {
    _loadEntries();
  }

  late final Box<TimeEntry> _box = Hive.box<TimeEntry>('time_entries');

  void _loadEntries() {
    state = _box.values.toList();
  }

  void refreshFromLocal() {
    state = _box.values.toList();
  }

  void clear() {
    state = [];
    _box.clear();
  }

  Future<void> addEntry(TimeEntry entry) async {
    // 1. Hive local save
    await _box.put(entry.id, entry);
    // 2. State update
    state = _box.values.toList();
    // 3. Firestore async sync
    await _firestoreService.saveTimeEntry(entry);
  }

  Future<void> updateEntry(TimeEntry entry) async {
    // 1. Hive local save
    await _box.put(entry.id, entry);
    // 2. State update
    state = _box.values.toList();
    // 3. Firestore async sync
    await _firestoreService.saveTimeEntry(entry);
  }

  Future<void> deleteEntry(String id) async {
    // 1. Hive local delete
    await _box.delete(id);
    // 2. State update
    state = _box.values.toList();
    // 3. Firestore async sync
    await _firestoreService.deleteTimeEntry(id);
  }

  Future<void> markAsBilled(List<String> entryIds, String invoiceId) async {
    for (final id in entryIds) {
      final index = state.indexWhere((e) => e.id == id);
      if (index != -1) {
        final updated = state[index].copyWith(
          isBilled: true,
          invoiceId: invoiceId,
          isRunning: false,
        );
        await updateEntry(updated);
      }
    }
  }

  /// Converts selected unbilled time entries into an Invoice
  Future<Invoice?> convertToInvoice({
    required List<TimeEntry> entries,
    required WidgetRef ref,
  }) async {
    // Filter out already billed entries
    final eligibleEntries = entries.where((e) => !e.isBilled).toList();
    if (eligibleEntries.isEmpty) return null;

    final firstClient = eligibleEntries.first.client;
    final items = eligibleEntries.map((entry) {
      final hours = entry.durationSeconds / 3600.0;
      final hoursFormatted = hours >= 1.0
          ? '${hours.toStringAsFixed(1)} hrs'
          : '${(entry.durationSeconds ~/ 60)} mins';
      return InvoiceItem(
        id: 'item_${DateTime.now().millisecondsSinceEpoch}_${entry.id}',
        name: '${entry.projectTitle} ($hoursFormatted @ \$${entry.hourlyRate.toStringAsFixed(0)}/hr)',
        quantity: 1,
        price: entry.totalAmount,
      );
    }).toList();

    final invoiceNumber =
        'INV-${DateTime.now().year}-${(ref.read(invoiceProvider).length + 1).toString().padLeft(3, '0')}';
    final invoiceId = 'inv_${DateTime.now().millisecondsSinceEpoch}';

    final invoice = Invoice(
      id: invoiceId,
      invoiceNumber: invoiceNumber,
      client: firstClient,
      items: items,
      issueDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 14)),
      status: 'pending',
      notes: 'Generated from billable time tracker.',
    );

    await ref.read(invoiceProvider.notifier).addInvoice(invoice);
    await markAsBilled(eligibleEntries.map((e) => e.id).toList(), invoiceId);

    return invoice;
  }
}

final timeEntriesProvider = StateNotifierProvider<TimeEntriesNotifier, List<TimeEntry>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return TimeEntriesNotifier(firestoreService);
});

// ==================== LIVE ACTIVE STOPWATCH WITH CRASH RECOVERY ====================

class ActiveTimerState {
  final bool isRunning;
  final bool isPaused;
  final String? activeEntryId;
  final Client? client;
  final String? projectId;
  final String projectTitle;
  final double hourlyRate;
  final int elapsedSeconds;
  final DateTime? startTime;

  const ActiveTimerState({
    this.isRunning = false,
    this.isPaused = false,
    this.activeEntryId,
    this.client,
    this.projectId,
    this.projectTitle = '',
    this.hourlyRate = 50.0,
    this.elapsedSeconds = 0,
    this.startTime,
  });

  String get formattedTime {
    final hours = elapsedSeconds ~/ 3600;
    final minutes = (elapsedSeconds % 3600) ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get accumulatedEarnings => (elapsedSeconds / 3600.0) * hourlyRate;

  ActiveTimerState copyWith({
    bool? isRunning,
    bool? isPaused,
    String? activeEntryId,
    Client? client,
    String? projectId,
    String? projectTitle,
    double? hourlyRate,
    int? elapsedSeconds,
    DateTime? startTime,
  }) {
    return ActiveTimerState(
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      activeEntryId: activeEntryId ?? this.activeEntryId,
      client: client ?? this.client,
      projectId: projectId ?? this.projectId,
      projectTitle: projectTitle ?? this.projectTitle,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      startTime: startTime ?? this.startTime,
    );
  }
}

class ActiveTimerNotifier extends StateNotifier<ActiveTimerState> {
  Timer? _ticker;
  late final Box<TimeEntry> _box = Hive.box<TimeEntry>('time_entries');

  ActiveTimerNotifier() : super(const ActiveTimerState()) {
    _recoverRunningTimer();
  }

  /// Timestamp-based recovery on app launch/restart
  void _recoverRunningTimer() {
    try {
      final runningEntries = _box.values.where((e) => e.isRunning).toList();
      if (runningEntries.isNotEmpty) {
        final active = runningEntries.first;
        final elapsed = active.currentElapsedSeconds;

        state = ActiveTimerState(
          isRunning: true,
          isPaused: false,
          activeEntryId: active.id,
          client: active.client,
          projectId: active.projectId,
          projectTitle: active.projectTitle,
          hourlyRate: active.hourlyRate,
          elapsedSeconds: elapsed,
          startTime: active.startTime,
        );

        _startPeriodicTicker();
      }
    } catch (e) {
      debugPrint('Timer recovery error: $e');
    }
  }

  void _startPeriodicTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isRunning && !state.isPaused) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });
  }

  Future<void> startTimer({
    required Client client,
    String? projectId,
    required String projectTitle,
    required double hourlyRate,
  }) async {
    _ticker?.cancel();
    final startTime = DateTime.now();
    final entryId = 'time_${startTime.millisecondsSinceEpoch}';

    final entry = TimeEntry(
      id: entryId,
      client: client,
      projectId: projectId,
      projectTitle: projectTitle.isNotEmpty ? projectTitle : 'Consulting & Design',
      hourlyRate: hourlyRate,
      durationSeconds: 0,
      startTime: startTime,
      isRunning: true,
      date: startTime,
      createdAt: startTime,
    );

    // Save running entry in Hive immediately for restart recovery
    await _box.put(entryId, entry);

    state = ActiveTimerState(
      isRunning: true,
      isPaused: false,
      activeEntryId: entryId,
      client: client,
      projectId: projectId,
      projectTitle: entry.projectTitle,
      hourlyRate: hourlyRate,
      elapsedSeconds: 0,
      startTime: startTime,
    );

    _startPeriodicTicker();
  }

  Future<void> pauseTimer() async {
    if (!state.isRunning || state.isPaused) return;

    if (state.activeEntryId != null) {
      final entry = _box.get(state.activeEntryId);
      if (entry != null) {
        final updated = entry.copyWith(
          durationSeconds: state.elapsedSeconds,
          isRunning: false,
        );
        await _box.put(state.activeEntryId!, updated);
      }
    }

    state = state.copyWith(isPaused: true);
  }

  Future<void> resumeTimer() async {
    if (!state.isRunning || !state.isPaused) return;

    final now = DateTime.now();
    if (state.activeEntryId != null) {
      final entry = _box.get(state.activeEntryId);
      if (entry != null) {
        final updated = entry.copyWith(
          startTime: now,
          isRunning: true,
        );
        await _box.put(state.activeEntryId!, updated);
      }
    }

    state = state.copyWith(isPaused: false, startTime: now);
  }

  Future<TimeEntry?> stopAndSave(WidgetRef ref) async {
    _ticker?.cancel();
    _ticker = null;

    final finalSeconds = state.elapsedSeconds;
    final entryId = state.activeEntryId;
    final client = state.client;

    if (client == null || finalSeconds < 2) {
      if (entryId != null) {
        await _box.delete(entryId);
      }
      reset();
      return null;
    }

    final entry = TimeEntry(
      id: entryId ?? 'time_${DateTime.now().millisecondsSinceEpoch}',
      client: client,
      projectId: state.projectId,
      projectTitle: state.projectTitle.isNotEmpty ? state.projectTitle : 'Freelance Work',
      hourlyRate: state.hourlyRate,
      durationSeconds: finalSeconds,
      startTime: state.startTime ?? DateTime.now(),
      endTime: DateTime.now(),
      isRunning: false,
      date: DateTime.now(),
      createdAt: state.startTime ?? DateTime.now(),
    );

    // Save final state in Hive & cloud
    await ref.read(timeEntriesProvider.notifier).addEntry(entry);
    reset();
    return entry;
  }

  void reset() {
    _ticker?.cancel();
    _ticker = null;
    state = const ActiveTimerState();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final activeTimerProvider = StateNotifierProvider<ActiveTimerNotifier, ActiveTimerState>((ref) {
  return ActiveTimerNotifier();
});

// ==================== TIME STATS PROVIDER (DAILY & WEEKLY) ====================

final timeStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final entries = ref.watch(timeEntriesProvider);
  final now = DateTime.now();

  // Today start & end
  final startOfToday = DateTime(now.year, now.month, now.day);
  final endOfToday = startOfToday.add(const Duration(days: 1));

  // Current week start (Monday) & end
  final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 7));

  final todayEntries = entries.where((e) => e.date.isAfter(startOfToday) && e.date.isBefore(endOfToday)).toList();
  final weekEntries = entries.where((e) => e.date.isAfter(startOfWeek) && e.date.isBefore(endOfWeek)).toList();
  final unbilledEntries = entries.where((e) => !e.isBilled).toList();
  final billedEntries = entries.where((e) => e.isBilled).toList();

  final todaySeconds = todayEntries.fold(0, (sum, e) => sum + e.durationSeconds);
  final todayHours = todaySeconds / 3600.0;
  final todayAmount = todayEntries.fold(0.0, (sum, e) => sum + e.totalAmount);

  final weekSeconds = weekEntries.fold(0, (sum, e) => sum + e.durationSeconds);
  final weekHours = weekSeconds / 3600.0;
  final weekAmount = weekEntries.fold(0.0, (sum, e) => sum + e.totalAmount);

  final unbilledSeconds = unbilledEntries.fold(0, (sum, e) => sum + e.durationSeconds);
  final unbilledHours = unbilledSeconds / 3600.0;
  final unbilledAmount = unbilledEntries.fold(0.0, (sum, e) => sum + e.totalAmount);

  final billedSeconds = billedEntries.fold(0, (sum, e) => sum + e.durationSeconds);
  final billedHours = billedSeconds / 3600.0;
  final billedAmount = billedEntries.fold(0.0, (sum, e) => sum + e.totalAmount);

  return {
    'todayHours': todayHours,
    'todayAmount': todayAmount,
    'weekHours': weekHours,
    'weekAmount': weekAmount,
    'unbilledHours': unbilledHours,
    'unbilledAmount': unbilledAmount,
    'billedHours': billedHours,
    'billedAmount': billedAmount,
  };
});
