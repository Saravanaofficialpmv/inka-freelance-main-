import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../data/models/client.dart';
import '../../data/models/project.dart';
import '../../data/models/time_entry.dart';
import '../../services/currency_tax_service.dart';
import '../providers/client_provider.dart';
import '../providers/profile_provider.dart';
import '../viewmodels/project_viewmodel.dart';
import '../viewmodels/time_tracker_viewmodel.dart';

class TimeTrackerScreen extends ConsumerStatefulWidget {
  const TimeTrackerScreen({super.key});

  @override
  ConsumerState<TimeTrackerScreen> createState() => _TimeTrackerScreenState();
}

class _TimeTrackerScreenState extends ConsumerState<TimeTrackerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _selectedEntryIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showStartTimerDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _StartTimerBottomSheet(),
    );
  }

  void _showManualEntryDialog({TimeEntry? entryToEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ManualTimeEntryBottomSheet(entryToEdit: entryToEdit),
    );
  }

  Future<void> _handleConvertToInvoice(List<TimeEntry> unbilledEntries) async {
    final selectedEntries = unbilledEntries.where((e) => _selectedEntryIds.contains(e.id) && !e.isBilled).toList();
    if (selectedEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one unbilled time entry.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Verify all selected entries are for the same client
    final firstClientId = selectedEntries.first.client.id;
    final isSameClient = selectedEntries.every((e) => e.client.id == firstClientId);
    if (!isSameClient) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All selected entries must belong to the same client for a single invoice.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final invoice = await ref.read(timeEntriesProvider.notifier).convertToInvoice(
          entries: selectedEntries,
          ref: ref,
        );

    if (!mounted) return;
    if (invoice != null) {
      setState(() => _selectedEntryIds.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully created invoice #${invoice.invoiceNumber}!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      context.push('/preview', extra: invoice);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(timeEntriesProvider);
    final activeTimer = ref.watch(activeTimerProvider);
    final timeStats = ref.watch(timeStatsProvider);
    final profile = ref.watch(profileProvider);
    final currencyFormat = CurrencyTaxService.getCurrencyFormatter(
      currencyCode: profile.currency,
      decimalDigits: 2,
    );

    final unbilledEntries = entries.where((e) => !e.isBilled).toList().reversed.toList();
    final billedEntries = entries.where((e) => e.isBilled).toList().reversed.toList();

    final selectedTotalValue = unbilledEntries
        .where((e) => _selectedEntryIds.contains(e.id))
        .fold(0.0, (sum, e) => sum + e.totalAmount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Time Tracker',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            tooltip: 'Add Manual Entry',
            icon: const Icon(Icons.playlist_add_rounded, color: AppColors.primary, size: 26),
            onPressed: () => _showManualEntryDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Live Stopwatch Hero Card ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: activeTimer.isRunning && !activeTimer.isPaused
                                  ? AppColors.success
                                  : (activeTimer.isPaused ? AppColors.warning : Colors.grey),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            activeTimer.isRunning
                                ? (activeTimer.isPaused ? 'TIMER PAUSED' : 'TRACKING LIVE')
                                : 'STOPWATCH READY',
                            style: TextStyle(
                              color: activeTimer.isRunning && !activeTimer.isPaused
                                  ? AppColors.success
                                  : (activeTimer.isPaused ? AppColors.warning : const Color(0xFFA0A0A0)),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      if (activeTimer.isRunning && activeTimer.client != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            activeTimer.client!.name,
                            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Big Timer Digits
                  Text(
                    activeTimer.formattedTime,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      fontFeatures: [FontFeature.tabularFigures()],
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Project Title & Earned Counter
                  if (activeTimer.isRunning) ...[
                    Text(
                      activeTimer.projectTitle.isNotEmpty ? activeTimer.projectTitle : 'Freelance Session',
                      style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+${currencyFormat.format(activeTimer.accumulatedEarnings)} earned (${currencyFormat.format(activeTimer.hourlyRate)}/hr)',
                      style: const TextStyle(color: AppColors.primary, fontSize: 13.5, fontWeight: FontWeight.w800),
                    ),
                  ] else ...[
                    const Text(
                      'Select client, project and start tracking billable hours',
                      style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 12.5),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Action Buttons
                  Row(
                    children: [
                      if (!activeTimer.isRunning)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showStartTimerDialog,
                            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                            label: const Text(
                              'Start New Timer',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              fixedSize: const Size.fromHeight(50),
                              elevation: 0,
                            ),
                          ),
                        )
                      else ...[
                        // Pause / Resume
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              if (activeTimer.isPaused) {
                                ref.read(activeTimerProvider.notifier).resumeTimer();
                              } else {
                                ref.read(activeTimerProvider.notifier).pauseTimer();
                              }
                            },
                            icon: Icon(
                              activeTimer.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            label: Text(
                              activeTimer.isPaused ? 'Resume' : 'Pause',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              fixedSize: const Size.fromHeight(48),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Stop & Save
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final saved = await ref.read(activeTimerProvider.notifier).stopAndSave(ref);
                              if (!context.mounted) return;
                              if (saved != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Saved ${saved.formattedDuration} for ${saved.client.name}!'),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.stop_rounded, color: Colors.white, size: 20),
                            label: const Text(
                              'Stop & Log',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              fixedSize: const Size.fromHeight(48),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Daily & Weekly Summary Banner ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Today's Tracked", style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(timeStats['todayHours'] as double? ?? 0.0).toStringAsFixed(1)} hrs',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              currencyFormat.format(timeStats['todayAmount'] ?? 0.0),
                              style: const TextStyle(color: Color(0xFF10B981), fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('This Week', style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(timeStats['weekHours'] as double? ?? 0.0).toStringAsFixed(1)} hrs',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              currencyFormat.format(timeStats['weekAmount'] ?? 0.0),
                              style: const TextStyle(color: Color(0xFFFF5722), fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // ── Tabs: Unbilled vs Billed History ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFFFF5722),
                  borderRadius: BorderRadius.circular(14),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(text: 'Unbilled (${unbilledEntries.length})'),
                  Tab(text: 'Invoiced (${billedEntries.length})'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),

          // ── Tab Views ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Unbilled Tab
                _buildUnbilledTab(unbilledEntries, currencyFormat, timeStats['unbilledHours'] ?? 0.0, timeStats['unbilledAmount'] ?? 0.0),
                // Billed Tab
                _buildBilledTab(billedEntries, currencyFormat),
              ],
            ),
          ),

          // ── Convert to Invoice Sticky Bottom Bar ──
          if (_selectedEntryIds.isNotEmpty && unbilledEntries.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () => _handleConvertToInvoice(unbilledEntries),
                  icon: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
                  label: Text(
                    'Convert to Invoice (${_selectedEntryIds.length} • ${currencyFormat.format(selectedTotalValue)})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUnbilledTab(
    List<TimeEntry> entries,
    NumberFormat currencyFormat,
    double totalHours,
    double totalValue,
  ) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined, size: 48, color: const Color(0xFF94A3B8).withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text(
              'No unbilled time entries',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Track hours with the stopwatch above or log manual sessions.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      physics: const BouncingScrollPhysics(),
      children: [
        // Summary Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1ED),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFF5722).withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.hourglass_top_rounded, color: Color(0xFFFF5722), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${totalHours.toStringAsFixed(1)} unbilled hrs',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFBF360C), fontSize: 13),
                  ),
                ],
              ),
              Text(
                'Total: ${currencyFormat.format(totalValue)}',
                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFFF5722), fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Select All row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select items to invoice (${_selectedEntryIds.length}/${entries.length})',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selectedEntryIds.length == entries.length) {
                    _selectedEntryIds.clear();
                  } else {
                    _selectedEntryIds.addAll(entries.map((e) => e.id));
                  }
                });
              },
              child: Text(
                _selectedEntryIds.length == entries.length ? 'Deselect All' : 'Select All',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFF5722)),
              ),
            ),
          ],
        ),

        ...entries.map((entry) {
          final isSelected = _selectedEntryIds.contains(entry.id);
          return _TimeEntryCard(
            entry: entry,
            currencyFormat: currencyFormat,
            isSelected: isSelected,
            onToggleSelect: () {
              setState(() {
                if (isSelected) {
                  _selectedEntryIds.remove(entry.id);
                } else {
                  _selectedEntryIds.add(entry.id);
                }
              });
            },
            onEdit: () => _showManualEntryDialog(entryToEdit: entry),
            onDelete: () => ref.read(timeEntriesProvider.notifier).deleteEntry(entry.id),
          );
        }),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildBilledTab(List<TimeEntry> entries, NumberFormat currencyFormat) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 48, color: const Color(0xFF94A3B8).withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text(
              'No invoiced history yet',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            const Text(
              'When you convert tracked hours into invoices, they appear here.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      physics: const BouncingScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (ctx, index) {
        final entry = entries[index];
        return _TimeEntryCard(
          entry: entry,
          currencyFormat: currencyFormat,
          isSelected: false,
          isBilledView: true,
          onEdit: null,
          onDelete: () => ref.read(timeEntriesProvider.notifier).deleteEntry(entry.id),
        );
      },
    );
  }
}

class _TimeEntryCard extends StatelessWidget {
  final TimeEntry entry;
  final NumberFormat currencyFormat;
  final bool isSelected;
  final bool isBilledView;
  final VoidCallback? onToggleSelect;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  const _TimeEntryCard({
    required this.entry,
    required this.currencyFormat,
    this.isSelected = false,
    this.isBilledView = false,
    this.onToggleSelect,
    this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? const Color(0xFFFF5722) : const Color(0xFFE2E8F0),
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected ? const Color(0xFFFF5722).withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isBilledView) ...[
            GestureDetector(
              onTap: onToggleSelect,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFF5722) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFF5722) : const Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.projectTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      entry.client.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5, color: Color(0xFFFF5722)),
                    ),
                    const Text(' • ', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                    Text(
                      DateFormat('dd MMM yyyy').format(entry.date),
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        entry.formattedDuration,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${currencyFormat.format(entry.hourlyRate)}/hr)',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(entry.totalAmount),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              if (isBilledView)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'INVOICED',
                    style: TextStyle(color: AppColors.success, fontSize: 9.5, fontWeight: FontWeight.w800),
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                        onPressed: onEdit,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textSecondary),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Start Timer Modal Bottom Sheet ──
class _StartTimerBottomSheet extends ConsumerStatefulWidget {
  const _StartTimerBottomSheet();

  @override
  ConsumerState<_StartTimerBottomSheet> createState() => _StartTimerBottomSheetState();
}

class _StartTimerBottomSheetState extends ConsumerState<_StartTimerBottomSheet> {
  Client? _selectedClient;
  Project? _selectedProject;
  final _projectTitleController = TextEditingController();
  final _rateController = TextEditingController(text: '50');

  @override
  void dispose() {
    _projectTitleController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _handleStart() {
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a client to track hours for.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final rate = double.tryParse(_rateController.text.trim()) ?? 50.0;
    final projectTitle = _projectTitleController.text.trim().isNotEmpty
        ? _projectTitleController.text.trim()
        : (_selectedProject?.projectName ?? 'Freelance Work');

    ref.read(activeTimerProvider.notifier).startTimer(
          client: _selectedClient!,
          projectId: _selectedProject?.id,
          projectTitle: projectTitle,
          hourlyRate: rate,
        );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(clientsProvider);
    final projects = ref.watch(projectProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Start Time Tracking Session',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),

            // Select Client
            const Text('Client', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            DropdownButtonFormField<Client>(
              initialValue: _selectedClient,
              hint: const Text('Choose Client'),
              items: clients
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                  .toList(),
              onChanged: (c) {
                setState(() {
                  _selectedClient = c;
                  if (c != null && projects.isNotEmpty) {
                    final clientProjects = projects.where((p) => p.clientId == c.id).toList();
                    if (clientProjects.isNotEmpty) {
                      _selectedProject = clientProjects.first;
                      _projectTitleController.text = clientProjects.first.projectName;
                    }
                  }
                });
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),
            const SizedBox(height: 14),

            // Select Project (Optional)
            if (projects.isNotEmpty) ...[
              const Text('Project (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              DropdownButtonFormField<Project>(
                initialValue: _selectedProject,
                hint: const Text('Link to Project'),
                items: projects
                    .map((p) => DropdownMenuItem(value: p, child: Text('${p.projectName} (${p.clientName})')))
                    .toList(),
                onChanged: (p) {
                  setState(() {
                    _selectedProject = p;
                    if (p != null) {
                      _projectTitleController.text = p.projectName;
                      final matchedClient = clients.where((c) => c.id == p.clientId).toList();
                      if (matchedClient.isNotEmpty) _selectedClient = matchedClient.first;
                    }
                  });
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Work Description / Project Title
            const Text('Work Description / Task Title', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: _projectTitleController,
              decoration: InputDecoration(
                hintText: 'e.g. Flutter UI Development, API Integration',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),
            const SizedBox(height: 14),

            // Hourly Rate
            const Text('Hourly Rate (\$)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: _rateController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '50.00',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _handleStart,
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                label: const Text('Start Stopwatch', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Manual / Edit Time Entry Modal Bottom Sheet ──
class _ManualTimeEntryBottomSheet extends ConsumerStatefulWidget {
  final TimeEntry? entryToEdit;

  const _ManualTimeEntryBottomSheet({this.entryToEdit});

  @override
  ConsumerState<_ManualTimeEntryBottomSheet> createState() => _ManualTimeEntryBottomSheetState();
}

class _ManualTimeEntryBottomSheetState extends ConsumerState<_ManualTimeEntryBottomSheet> {
  Client? _selectedClient;
  Project? _selectedProject;
  late TextEditingController _projectTitleController;
  late TextEditingController _hoursController;
  late TextEditingController _rateController;

  @override
  void initState() {
    super.initState();
    final e = widget.entryToEdit;
    _selectedClient = e?.client;
    _projectTitleController = TextEditingController(text: e?.projectTitle ?? '');
    _hoursController = TextEditingController(
      text: e != null ? (e.durationSeconds / 3600.0).toStringAsFixed(1) : '1.5',
    );
    _rateController = TextEditingController(
      text: e != null ? e.hourlyRate.toStringAsFixed(0) : '50',
    );
  }

  @override
  void dispose() {
    _projectTitleController.dispose();
    _hoursController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a client.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final hours = double.tryParse(_hoursController.text.trim()) ?? 1.0;
    final rate = double.tryParse(_rateController.text.trim()) ?? 50.0;
    final durationSeconds = (hours * 3600).toInt();

    final isEdit = widget.entryToEdit != null;
    final entry = TimeEntry(
      id: isEdit ? widget.entryToEdit!.id : 'time_${DateTime.now().millisecondsSinceEpoch}',
      client: _selectedClient!,
      projectId: _selectedProject?.id ?? widget.entryToEdit?.projectId,
      projectTitle: _projectTitleController.text.trim().isNotEmpty
          ? _projectTitleController.text.trim()
          : 'Consulting & Design',
      hourlyRate: rate,
      durationSeconds: durationSeconds,
      date: isEdit ? widget.entryToEdit!.date : DateTime.now(),
      startTime: isEdit ? widget.entryToEdit!.startTime : DateTime.now(),
      endTime: isEdit ? widget.entryToEdit!.endTime : DateTime.now(),
      isBilled: isEdit ? widget.entryToEdit!.isBilled : false,
      invoiceId: isEdit ? widget.entryToEdit!.invoiceId : null,
      createdAt: isEdit ? widget.entryToEdit!.createdAt : DateTime.now(),
    );

    if (isEdit) {
      ref.read(timeEntriesProvider.notifier).updateEntry(entry);
    } else {
      ref.read(timeEntriesProvider.notifier).addEntry(entry);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(clientsProvider);
    final projects = ref.watch(projectProvider);
    final isEdit = widget.entryToEdit != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEdit ? 'Edit Time Entry' : 'Log Manual Time Entry',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),

            // Select Client
            const Text('Client', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            DropdownButtonFormField<Client>(
              initialValue: _selectedClient,
              hint: const Text('Choose Client'),
              items: clients
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                  .toList(),
              onChanged: (c) => setState(() => _selectedClient = c),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),
            const SizedBox(height: 14),

            // Select Project
            if (projects.isNotEmpty) ...[
              const Text('Project (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              DropdownButtonFormField<Project>(
                initialValue: _selectedProject,
                hint: const Text('Choose Project'),
                items: projects
                    .map((p) => DropdownMenuItem(value: p, child: Text('${p.projectName} (${p.clientName})')))
                    .toList(),
                onChanged: (p) {
                  setState(() {
                    _selectedProject = p;
                    if (p != null) {
                      _projectTitleController.text = p.projectName;
                    }
                  });
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Project Title / Description
            const Text('Work Description / Task Title', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: _projectTitleController,
              decoration: InputDecoration(
                hintText: 'e.g. Code Review, System Architecture',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),
            const SizedBox(height: 14),

            // Hours & Rate
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Hours', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _hoursController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: '2.5',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hourly Rate (\$)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _rateController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '50.00',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                  elevation: 0,
                ),
                child: Text(
                  isEdit ? 'Save Changes' : 'Save Time Entry',
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
