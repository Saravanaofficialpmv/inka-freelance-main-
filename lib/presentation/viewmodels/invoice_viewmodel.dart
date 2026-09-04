import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../providers/client_provider.dart';
import '../../data/models/invoice.dart';
import '../../services/firestore_service.dart';

class InvoiceNotifier extends StateNotifier<List<Invoice>> {
  final FirestoreService _firestoreService;

  InvoiceNotifier(this._firestoreService) : super([]) {
    _loadInvoices();
  }

  late final Box<Invoice> _invoiceBox = Hive.box<Invoice>('invoices');

  void _loadInvoices() {
    state = _invoiceBox.values.toList();
    checkAndRenewRecurringInvoices();
  }

  void refreshFromLocal() {
    state = _invoiceBox.values.toList();
  }

  void clear() {
    state = [];
    _invoiceBox.clear();
  }

  Future<void> addInvoice(Invoice invoice) async {
    await _invoiceBox.put(invoice.id, invoice);
    state = _invoiceBox.values.toList();
    await _firestoreService.saveInvoice(invoice);
  }

  Future<void> updateInvoice(Invoice updatedInvoice) async {
    await _invoiceBox.put(updatedInvoice.id, updatedInvoice);
    state = _invoiceBox.values.toList();
    await _firestoreService.saveInvoice(updatedInvoice);
  }

  Future<void> togglePaymentStatus(String id) async {
    HapticFeedback.mediumImpact();
    final invoice = state.firstWhere((inv) => inv.id == id);
    final newStatus = invoice.status == 'paid' ? 'pending' : 'paid';
    await updateInvoice(invoice.copyWith(status: newStatus));
  }

  Future<void> togglePaid(String id) => togglePaymentStatus(id);

  Future<void> toggleRecurring(String id, {required bool isRecurring, String? interval}) async {
    final invoice = state.firstWhere((inv) => inv.id == id);
    final nextDate = isRecurring
        ? calculateNextRecurringDate(DateTime.now(), interval ?? invoice.recurringInterval)
        : null;
    await updateInvoice(invoice.copyWith(
      isRecurring: isRecurring,
      recurringInterval: interval ?? invoice.recurringInterval,
      nextRecurringDate: nextDate,
    ));
  }

  /// Duplicates an existing invoice with a new generated invoice number, fresh issue date, and pending status.
  Future<Invoice> duplicateAsNewInvoice(Invoice originalInvoice) async {
    final newNumber = _generateNextInvoiceNumber();
    final newInvoice = originalInvoice.copyWith(
      id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
      invoiceNumber: newNumber,
      issueDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 14)),
      status: 'pending',
      nextRecurringDate: originalInvoice.isRecurring
          ? calculateNextRecurringDate(DateTime.now(), originalInvoice.recurringInterval)
          : null,
    );

    await addInvoice(newInvoice);
    return newInvoice;
  }

  /// Automatically generates next cycle invoices for recurring retainers whose renewal date has passed.
  Future<void> checkAndRenewRecurringInvoices() async {
    final now = DateTime.now();
    final recurringInvoices = state.where((inv) =>
        inv.isRecurring &&
        inv.nextRecurringDate != null &&
        inv.nextRecurringDate!.isBefore(now)).toList();

    for (final oldInvoice in recurringInvoices) {
      final nextInvoice = oldInvoice.copyWith(
        id: 'inv_${DateTime.now().millisecondsSinceEpoch}_${oldInvoice.id}',
        invoiceNumber: _generateNextInvoiceNumber(),
        issueDate: DateTime.now(),
        dueDate: calculateNextRecurringDate(DateTime.now(), oldInvoice.recurringInterval),
        status: 'pending',
        nextRecurringDate: calculateNextRecurringDate(
          calculateNextRecurringDate(DateTime.now(), oldInvoice.recurringInterval),
          oldInvoice.recurringInterval,
        ),
      );

      // Advance next recurring date on the source template
      await updateInvoice(oldInvoice.copyWith(
        nextRecurringDate: calculateNextRecurringDate(now, oldInvoice.recurringInterval),
      ));

      await addInvoice(nextInvoice);
    }
  }

  static DateTime calculateNextRecurringDate(DateTime fromDate, String interval) {
    switch (interval.toLowerCase()) {
      case 'weekly':
        return fromDate.add(const Duration(days: 7));
      case 'quarterly':
        return DateTime(fromDate.year, fromDate.month + 3, fromDate.day);
      case 'yearly':
        return DateTime(fromDate.year + 1, fromDate.month, fromDate.day);
      case 'monthly':
      default:
        return DateTime(fromDate.year, fromDate.month + 1, fromDate.day);
    }
  }

  String _generateNextInvoiceNumber() {
    final count = state.length + 1;
    final year = DateTime.now().year;
    return 'INV-$year-${count.toString().padLeft(3, '0')}';
  }

  Future<void> deleteInvoice(String id) async {
    await _invoiceBox.delete(id);
    state = _invoiceBox.values.toList();
    await _firestoreService.deleteInvoice(id);
  }
}

final invoiceProvider = StateNotifierProvider<InvoiceNotifier, List<Invoice>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return InvoiceNotifier(firestoreService);
});

enum StatsPeriod { today, last7Days, last30Days, allTime }

final statsPeriodProvider = StateProvider<StatsPeriod>((ref) => StatsPeriod.allTime);

final dashboardStatsProvider = Provider((ref) {
  final invoices = ref.watch(invoiceProvider);
  final clients = ref.watch(clientsProvider);
  final period = ref.watch(statsPeriodProvider);

  double totalRevenue = 0;
  double collectedRevenue = 0;
  double unpaidRevenue = 0;
  double pendingAmount = 0;
  int overdueCount = 0;
  int recurringCount = 0;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  
  DateTime? filterDate;
  if (period == StatsPeriod.today) {
    filterDate = today;
  } else if (period == StatsPeriod.last7Days) {
    filterDate = today.subtract(const Duration(days: 7));
  } else if (period == StatsPeriod.last30Days) {
    filterDate = today.subtract(const Duration(days: 30));
  }

  for (var invoice in invoices) {
    if (invoice.isRecurring) {
      recurringCount++;
    }

    // If filtering by date, only consider invoices on or after filterDate
    if (filterDate != null && invoice.issueDate.isBefore(filterDate)) {
      continue;
    }

    totalRevenue += invoice.total;

    if (invoice.status == 'paid') {
      collectedRevenue += invoice.total;
    } else {
      unpaidRevenue += invoice.total;
      pendingAmount += invoice.total;
      if (invoice.dueDate.isBefore(today)) {
        overdueCount++;
      }
    }
  }

  DateTime? prevStartDate;
  DateTime? prevEndDate = filterDate;
  if (period == StatsPeriod.today) {
    prevStartDate = today.subtract(const Duration(days: 1));
  } else if (period == StatsPeriod.last7Days) {
    prevStartDate = today.subtract(const Duration(days: 14));
  } else if (period == StatsPeriod.last30Days) {
    prevStartDate = today.subtract(const Duration(days: 60));
  }

  double previousRevenue = 0;
  if (prevStartDate != null) {
    for (var invoice in invoices) {
      if (invoice.issueDate.isAtSameMomentAs(prevStartDate) || (invoice.issueDate.isAfter(prevStartDate) && invoice.issueDate.isBefore(prevEndDate!))) {
        previousRevenue += invoice.total;
      }
    }
  }

  double growth = 0;
  if (previousRevenue > 0) {
    growth = ((totalRevenue - previousRevenue) / previousRevenue) * 100;
  } else if (totalRevenue > 0) {
    growth = 100; // 100% growth if starting from zero
  }

  return {
    'totalRevenue': totalRevenue,
    'collectedRevenue': collectedRevenue,
    'unpaidRevenue': unpaidRevenue,
    'pendingAmount': pendingAmount,
    'totalInvoices': invoices.length,
    'totalClients': clients.length,
    'overdueCount': overdueCount,
    'recurringCount': recurringCount,
    'revenueGrowth': growth,
    'isGrowthPositive': growth >= 0,
  };
});
