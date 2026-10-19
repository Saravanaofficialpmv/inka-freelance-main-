import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../data/models/expense.dart';
import '../../data/models/invoice.dart';
import '../../services/currency_tax_service.dart';
import '../providers/profile_provider.dart';
import '../viewmodels/expense_viewmodel.dart';
import '../viewmodels/invoice_viewmodel.dart';
import '../widgets/tibsy_refresh_icon.dart';
import '../../core/theme/theme_helper.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {

  void _showAddExpenseModal([Expense? existingExpense]) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ExpenseFormBottomSheet(
        expense: existingExpense,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expenseProvider);
    final invoices = ref.watch(invoiceProvider);
    final profile = ref.watch(profileProvider);
    final currencyFormat = CurrencyTaxService.getCurrencyFormatter(
      currencyCode: profile.currency.isNotEmpty ? profile.currency : 'USD',
      decimalDigits: 0,
    );

    final now = DateTime.now();
    final monthName = DateFormat('MMMM').format(now);

    final totalRevenue = invoices.fold(0.0, (s, i) => s + i.total);
    final paidAmount = invoices.where((i) => i.isPaid).fold(0.0, (s, i) => s + i.total);
    final unpaidAmount = invoices.where((i) => !i.isPaid && !i.dueDate.isBefore(now)).fold(0.0, (s, i) => s + i.total);
    final overdueAmount = invoices.where((i) => !i.isPaid && i.dueDate.isBefore(now)).fold(0.0, (s, i) => s + i.total);
    final totalExpenses = expenses.fold(0.0, (s, e) => s + e.amount);
    final netProfit = totalRevenue - totalExpenses;
    final profitMargin = totalRevenue > 0 ? ((netProfit / totalRevenue) * 100) : 0.0;

    final sortedExpenses = expenses.reversed.toList();
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar (Back if canPop, Title "Statistics", Add CTA) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (Navigator.of(context).canPop())
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 44,
                              height: 44,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: context.circleBtnBg,
                                shape: BoxShape.circle,
                                border: Border.all(color: context.cardBorder, width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 18),
                            ),
                          ),
                        Flexible(
                          child: Text(
                            'Statistics',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showAddExpenseModal(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5722), Color(0xFFFF7A50)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5722).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable Body ──
            Expanded(
              child: TibsyPullToRefresh(
                padding: EdgeInsets.fromLTRB(20, 8, 20, isWide ? 32 : 140),
                onRefresh: () => syncAndRefreshEntireApp(ref),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title: "Overview"
                    const Text(
                      'Overview',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Summary Banner (Orange Gradient Card) ──
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5722), Color(0xFFFF7A50)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5722).withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$monthName Invoicing Summary',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              // Paid
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Paid', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        currencyFormat.format(paidAmount),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.25)),
                              const SizedBox(width: 12),

                              // Unpaid
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Unpaid', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        currencyFormat.format(unpaidAmount),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 12),
                              Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.25)),
                              const SizedBox(width: 12),

                              // Overdue
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Overdue', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        currencyFormat.format(overdueAmount),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── Financial Health (Expenses vs Net Profit) ──
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Total Spent
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.arrow_outward_rounded, color: Color(0xFFEF4444), size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Total Spent', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 3),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          currencyFormat.format(totalExpenses),
                                          style: const TextStyle(
                                            color: Color(0xFF0F172A),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
                          const SizedBox(width: 12),

                          // Net Profit
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: (netProfit >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    netProfit >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                    color: netProfit >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Net Profit (${profitMargin.toStringAsFixed(0)}%)',
                                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 3),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          currencyFormat.format(netProfit),
                                          style: TextStyle(
                                            color: netProfit >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── Fully Functional Analytics Curve Chart Card ──
                    _FunctionalPerformanceChartCard(
                      invoices: invoices,
                      expenses: expenses,
                      currencyFormat: currencyFormat,
                    ),

                    const SizedBox(height: 24),

                    // ── Top Spending Section ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Top Spending',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showAddExpenseModal(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0EB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFF5722).withValues(alpha: 0.25)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded, size: 15, color: Color(0xFFFF5722)),
                                SizedBox(width: 4),
                                Text(
                                  'Add Expense',
                                  style: TextStyle(
                                    color: Color(0xFFFF5722),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (sortedExpenses.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Center(
                          child: Column(
                            children: const [
                              Icon(Icons.shopping_bag_outlined, size: 40, color: Color(0xFFCBD5E1)),
                              SizedBox(height: 12),
                              Text('No expenses recorded yet', style: TextStyle(color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      )
                    else
                      ...sortedExpenses.map((expense) {
                        return GestureDetector(
                          onTap: () => _showAddExpenseModal(expense),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Circular Brand/Category Icon
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(expense.category).withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(expense.category),
                                    color: _getCategoryColor(expense.category),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Description & Date
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        expense.title.isNotEmpty ? expense.title : expense.category,
                                        style: const TextStyle(
                                          color: Color(0xFF0F172A),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat('dd MMM, yyyy').format(expense.date),
                                        style: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Amount
                                Text(
                                  currencyFormat.format(expense.amount),
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'software':
        return Icons.code_rounded;
      case 'equipment':
        return Icons.devices_rounded;
      case 'office':
        return Icons.business_rounded;
      case 'marketing':
        return Icons.campaign_rounded;
      case 'travel':
        return Icons.flight_rounded;
      case 'utilities':
        return Icons.bolt_rounded;
      default:
        return Icons.shopping_bag_outlined;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'software':
        return const Color(0xFF3B82F6);
      case 'equipment':
        return const Color(0xFF8B5CF6);
      case 'office':
        return const Color(0xFFFF5722);
      case 'marketing':
        return const Color(0xFFEC4899);
      case 'travel':
        return const Color(0xFF14B8A6);
      case 'utilities':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFFF5722);
    }
  }
}

// ── Fully Functional Performance Curve Chart ──

class _PerformanceDataPoint {
  final String label;
  final String fullLabel;
  final DateTime startDate;
  final DateTime endDate;
  final double revenue;
  final double expense;

  const _PerformanceDataPoint({
    required this.label,
    required this.fullLabel,
    required this.startDate,
    required this.endDate,
    required this.revenue,
    required this.expense,
  });
}

class _FunctionalPerformanceChartCard extends StatefulWidget {
  final List<Invoice> invoices;
  final List<Expense> expenses;
  final NumberFormat currencyFormat;

  const _FunctionalPerformanceChartCard({
    required this.invoices,
    required this.expenses,
    required this.currencyFormat,
  });

  @override
  State<_FunctionalPerformanceChartCard> createState() => _FunctionalPerformanceChartCardState();
}

class _FunctionalPerformanceChartCardState extends State<_FunctionalPerformanceChartCard> {
  String _timeframe = 'Monthly'; // 'Weekly', 'Monthly', 'Yearly'
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final points = _generateDataPoints();

    final totalRevenue = points.fold<double>(0.0, (sum, p) => sum + p.revenue);
    final growthPct = _calculateGrowth(points);

    final isScrubbing = _touchedIndex != null && _touchedIndex! >= 0 && _touchedIndex! < points.length;
    final activePoint = isScrubbing ? points[_touchedIndex!] : null;
    final displayRevenue = activePoint != null ? activePoint.revenue : totalRevenue;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Total Amount + Growth Badge + Timeframe Dropdown ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.currencyFormat.format(displayRevenue),
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: growthPct >= 0
                            ? const Color(0xFFE8F8F0)
                            : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${growthPct >= 0 ? '+' : ''}${growthPct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: growthPct >= 0
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Timeframe Dropdown Pill
              PopupMenuButton<String>(
                initialValue: _timeframe,
                tooltip: 'Select Timeframe',
                onSelected: (val) {
                  setState(() {
                    _timeframe = val;
                    _touchedIndex = null;
                  });
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                itemBuilder: (ctx) => [
                  _buildMenuItem('Weekly'),
                  _buildMenuItem('Monthly'),
                  _buildMenuItem('Yearly'),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7F4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFDCD1), width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _timeframe,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFFFF5722),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Interactive Legend & Scrubber Indicator Bar ──
          if (activePoint != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Text(
                    activePoint.fullLabel,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  _buildLegendDot(const Color(0xFFFF5722)),
                  const SizedBox(width: 4),
                  Text(
                    widget.currencyFormat.format(activePoint.revenue),
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildLegendDot(const Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  Text(
                    widget.currencyFormat.format(activePoint.expense),
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  _buildLegendDot(const Color(0xFFFF5722)),
                  const SizedBox(width: 5),
                  const Text(
                    'Revenue',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 14),
                  _buildLegendDot(const Color(0xFF10B981)),
                  const SizedBox(width: 5),
                  const Text(
                    'Expenses',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // ── Curve Chart Canvas with Pan & Tap Gesture Tracking ──
          LayoutBuilder(
            builder: (context, constraints) {
              final chartWidth = constraints.maxWidth;
              const chartHeight = 150.0;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanDown: (details) => _handleTouch(details.localPosition, chartWidth, points.length),
                onPanUpdate: (details) => _handleTouch(details.localPosition, chartWidth, points.length),
                onTapUp: (details) => _handleTouch(details.localPosition, chartWidth, points.length),
                child: SizedBox(
                  width: chartWidth,
                  height: chartHeight + 36, // extra space for bottom X-axis labels
                  child: CustomPaint(
                    size: Size(chartWidth, chartHeight + 36),
                    painter: _InteractiveCurveChartPainter(
                      points: points,
                      touchedIndex: _touchedIndex,
                      chartHeight: chartHeight,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleTouch(Offset localPosition, double totalWidth, int count) {
    if (count <= 1) return;
    const leftMargin = 38.0;
    const rightMargin = 12.0;
    final usableWidth = totalWidth - leftMargin - rightMargin;
    if (usableWidth <= 0) return;

    final x = (localPosition.dx - leftMargin).clamp(0.0, usableWidth);
    final index = ((x / usableWidth) * (count - 1)).round().clamp(0, count - 1);

    if (_touchedIndex != index) {
      Feedback.forTap(context);
      setState(() => _touchedIndex = index);
    }
  }

  PopupMenuItem<String> _buildMenuItem(String title) {
    final isSelected = _timeframe == title;
    return PopupMenuItem<String>(
      value: title,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isSelected ? const Color(0xFFFF5722) : const Color(0xFF0F172A),
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 14,
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_rounded, color: Color(0xFFFF5722), size: 18),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  List<_PerformanceDataPoint> _generateDataPoints() {
    final now = DateTime.now();

    if (_timeframe == 'Weekly') {
      DateTime anchor = now;
      final hasRecent = widget.invoices.any((i) => i.issueDate.isAfter(now.subtract(const Duration(days: 7))));
      if (!hasRecent && widget.invoices.isNotEmpty) {
        anchor = widget.invoices.map((i) => i.issueDate).reduce((a, b) => a.isAfter(b) ? a : b);
      }

      return List.generate(7, (i) {
        final dayOffset = 6 - i;
        final date = anchor.subtract(Duration(days: dayOffset));
        final start = DateTime(date.year, date.month, date.day);
        final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

        final rev = widget.invoices
            .where((inv) => !inv.issueDate.isBefore(start) && !inv.issueDate.isAfter(end))
            .fold<double>(0.0, (s, inv) => s + inv.total);

        final exp = widget.expenses
            .where((e) => !e.date.isBefore(start) && !e.date.isAfter(end))
            .fold<double>(0.0, (s, e) => s + e.amount);

        return _PerformanceDataPoint(
          label: DateFormat('E').format(date),
          fullLabel: DateFormat('EEE, dd MMM yyyy').format(date),
          startDate: start,
          endDate: end,
          revenue: rev,
          expense: exp,
        );
      });
    } else if (_timeframe == 'Yearly') {
      return List.generate(5, (i) {
        final year = now.year - (4 - i);
        final start = DateTime(year, 1, 1);
        final end = DateTime(year, 12, 31, 23, 59, 59);

        final rev = widget.invoices
            .where((inv) => !inv.issueDate.isBefore(start) && !inv.issueDate.isAfter(end))
            .fold<double>(0.0, (s, inv) => s + inv.total);

        final exp = widget.expenses
            .where((e) => !e.date.isBefore(start) && !e.date.isAfter(end))
            .fold<double>(0.0, (s, e) => s + e.amount);

        return _PerformanceDataPoint(
          label: '$year',
          fullLabel: 'Year $year',
          startDate: start,
          endDate: end,
          revenue: rev,
          expense: exp,
        );
      });
    } else {
      // 'Monthly': 8 consecutive months (matches Screenshot 1)
      return List.generate(8, (i) {
        final monthOffset = 7 - i;
        final monthDate = DateTime(now.year, now.month - monthOffset, 1);
        final start = DateTime(monthDate.year, monthDate.month, 1);
        final end = DateTime(monthDate.year, monthDate.month + 1, 0, 23, 59, 59);

        final rev = widget.invoices
            .where((inv) => !inv.issueDate.isBefore(start) && !inv.issueDate.isAfter(end))
            .fold<double>(0.0, (s, inv) => s + inv.total);

        final exp = widget.expenses
            .where((e) => !e.date.isBefore(start) && !e.date.isAfter(end))
            .fold<double>(0.0, (s, e) => s + e.amount);

        return _PerformanceDataPoint(
          label: DateFormat('MMM').format(monthDate),
          fullLabel: DateFormat('MMMM yyyy').format(monthDate),
          startDate: start,
          endDate: end,
          revenue: rev,
          expense: exp,
        );
      });
    }
  }

  double _calculateGrowth(List<_PerformanceDataPoint> points) {
    if (points.isEmpty) return 0.0;
    final currentRevenue = points.fold<double>(0.0, (sum, p) => sum + p.revenue);

    final periodDuration = points.last.endDate.difference(points.first.startDate);
    final prevStart = points.first.startDate.subtract(periodDuration);
    final prevEnd = points.first.startDate;

    final prevRevenue = widget.invoices
        .where((inv) => inv.issueDate.isAfter(prevStart) && inv.issueDate.isBefore(prevEnd))
        .fold<double>(0.0, (sum, inv) => sum + inv.total);

    if (prevRevenue > 0) {
      return ((currentRevenue - prevRevenue) / prevRevenue) * 100.0;
    } else if (currentRevenue > 0) {
      return 100.0;
    }
    return 0.0;
  }
}

// ── Custom Painter for Real Data-Driven Curve Line Chart ──

class _InteractiveCurveChartPainter extends CustomPainter {
  final List<_PerformanceDataPoint> points;
  final int? touchedIndex;
  final double chartHeight;

  _InteractiveCurveChartPainter({
    required this.points,
    required this.touchedIndex,
    required this.chartHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const leftMargin = 38.0;
    const rightMargin = 12.0;
    const topMargin = 8.0;
    final usableWidth = size.width - leftMargin - rightMargin;
    final count = points.length;

    // Determine scale based on maximum data value
    final maxRevenue = points.map((p) => p.revenue).fold<double>(0.0, math.max);
    final maxExpense = points.map((p) => p.expense).fold<double>(0.0, math.max);
    final highest = math.max(maxRevenue, maxExpense);
    final niceMax = _calculateNiceMax(highest);

    // ── 1. Draw 5 Horizontal Grid Lines and Y-Axis Labels ──
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    for (int i = 0; i < 5; i++) {
      final y = topMargin + (chartHeight * (i / 4.0));
      canvas.drawLine(
        Offset(leftMargin, y),
        Offset(size.width - rightMargin, y),
        gridPaint,
      );

      final stepVal = niceMax * (1.0 - (i / 4.0));
      final labelText = _formatAxisValue(stepVal, niceMax >= 1000);

      final textPainter = TextPainter(
        text: TextSpan(
          text: labelText,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(leftMargin - textPainter.width - 6, y - (textPainter.height / 2)),
      );
    }

    // ── 2. Compute Coordinate Offsets for Each Point ──
    final List<Offset> revenueOffsets = [];
    final List<Offset> expenseOffsets = [];

    for (int i = 0; i < count; i++) {
      final x = leftMargin + (usableWidth * (count > 1 ? i / (count - 1) : 0.5));
      final revRatio = (points[i].revenue / niceMax).clamp(0.0, 1.0);
      final expRatio = (points[i].expense / niceMax).clamp(0.0, 1.0);

      final yRev = topMargin + (chartHeight * (1.0 - revRatio));
      final yExp = topMargin + (chartHeight * (1.0 - expRatio));

      revenueOffsets.add(Offset(x, yRev));
      expenseOffsets.add(Offset(x, yExp));

      // ── Draw X-Axis Labels ──
      final isTouched = touchedIndex == i;
      final xTextPainter = TextPainter(
        text: TextSpan(
          text: points[i].label,
          style: TextStyle(
            color: isTouched ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: isTouched ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      xTextPainter.paint(
        canvas,
        Offset(x - (xTextPainter.width / 2), topMargin + chartHeight + 10),
      );
    }

    final bottomY = topMargin + chartHeight;

    // ── 3. Build Smooth Catmull-Rom Bezier Splines ──
    final revenuePath = _buildSmoothSplinePath(revenueOffsets, topMargin, bottomY);
    final expensePath = _buildSmoothSplinePath(expenseOffsets, topMargin, bottomY);

    // ── 4. Orange Gradient Area Fill ──
    final fillPath = Path.from(revenuePath)
      ..lineTo(revenueOffsets.last.dx, bottomY)
      ..lineTo(revenueOffsets.first.dx, bottomY)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFF5722).withValues(alpha: 0.22),
          const Color(0xFFFF5722).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(leftMargin, topMargin, usableWidth, chartHeight));

    canvas.drawPath(fillPath, fillPaint);

    // ── 5. Draw Primary Orange Line (Revenue) ──
    final revenueLinePaint = Paint()
      ..color = const Color(0xFFFF5722)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(revenuePath, revenueLinePaint);

    // ── 6. Draw Secondary Mint Green Line (Expenses) ──
    final expenseLinePaint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(expensePath, expenseLinePaint);

    // ── 7. Highlight Data Point Dots ──
    final dotOuterPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    if (touchedIndex != null && touchedIndex! >= 0 && touchedIndex! < count) {
      final tIdx = touchedIndex!;
      final touchX = revenueOffsets[tIdx].dx;

      // Draw subtle vertical guide line at touched X
      final guidePaint = Paint()
        ..color = const Color(0xFFE2E8F0)
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(touchX, topMargin), Offset(touchX, bottomY), guidePaint);

      // Revenue dot
      canvas.drawCircle(revenueOffsets[tIdx], 5.5, Paint()..color = const Color(0xFFFF5722));
      canvas.drawCircle(revenueOffsets[tIdx], 5.5, dotOuterPaint);

      // Expense dot
      canvas.drawCircle(expenseOffsets[tIdx], 5.5, Paint()..color = const Color(0xFF10B981));
      canvas.drawCircle(expenseOffsets[tIdx], 5.5, dotOuterPaint);
    } else {
      // When idle, highlight peak/active points (matches Screenshot 1 design)
      int revHighlightIdx = 0;
      int expHighlightIdx = 0;
      double peakRev = -1.0;
      double peakExp = -1.0;

      for (int i = 0; i < count; i++) {
        if (points[i].revenue >= peakRev) {
          peakRev = points[i].revenue;
          revHighlightIdx = i;
        }
        if (points[i].expense >= peakExp) {
          peakExp = points[i].expense;
          expHighlightIdx = i;
        }
      }

      // If all zero, default to middle-to-end indices (like Jun & Jul in Screenshot 1)
      if (peakRev <= 0 && count >= 7) revHighlightIdx = count - 3;
      if (peakExp <= 0 && count >= 7) expHighlightIdx = count - 2;

      // Draw orange dot on revenue line
      canvas.drawCircle(revenueOffsets[revHighlightIdx], 4.5, Paint()..color = const Color(0xFFFF5722));
      canvas.drawCircle(revenueOffsets[revHighlightIdx], 4.5, dotOuterPaint);

      // Draw green dot on expense line
      canvas.drawCircle(expenseOffsets[expHighlightIdx], 4.5, Paint()..color = const Color(0xFF10B981));
      canvas.drawCircle(expenseOffsets[expHighlightIdx], 4.5, dotOuterPaint);
    }
  }

  Path _buildSmoothSplinePath(List<Offset> pts, double minY, double maxY) {
    final path = Path();
    if (pts.isEmpty) return path;
    if (pts.length == 1) {
      path.moveTo(pts[0].dx, pts[0].dy);
      return path;
    }

    path.moveTo(pts[0].dx, pts[0].dy);

    if (pts.length == 2) {
      path.lineTo(pts[1].dx, pts[1].dy);
      return path;
    }

    const alpha = 0.1667;
    for (int i = 0; i < pts.length - 1; i++) {
      final pPrev = i > 0 ? pts[i - 1] : pts[i];
      final pCurr = pts[i];
      final pNext = pts[i + 1];
      final pNext2 = (i + 2 < pts.length) ? pts[i + 2] : pNext;

      final cp1x = pCurr.dx + (pNext.dx - pPrev.dx) * alpha;
      final cp1y = (pCurr.dy + (pNext.dy - pPrev.dy) * alpha).clamp(minY, maxY);

      final cp2x = pNext.dx - (pNext2.dx - pCurr.dx) * alpha;
      final cp2y = (pNext.dy - (pNext2.dy - pCurr.dy) * alpha).clamp(minY, maxY);

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, pNext.dx, pNext.dy);
    }

    return path;
  }

  static double _calculateNiceMax(double val) {
    if (val <= 0) return 1000.0;
    final magnitude = math.pow(10, (math.log(val) / math.ln10).floor()).toDouble();
    final normalized = val / magnitude;
    double niceNormalized;
    if (normalized <= 1.0) {
      niceNormalized = 1.0;
    } else if (normalized <= 2.0) {
      niceNormalized = 2.0;
    } else if (normalized <= 4.0) {
      niceNormalized = 4.0;
    } else if (normalized <= 6.0) {
      niceNormalized = 6.0;
    } else if (normalized <= 8.0) {
      niceNormalized = 8.0;
    } else {
      niceNormalized = 10.0;
    }
    return niceNormalized * magnitude;
  }

  static String _formatAxisValue(double value, bool isKScale) {
    if (value <= 0) {
      return isKScale ? '0k' : '0';
    }
    if (value >= 10000000) {
      final v = value / 10000000;
      return '${v == v.roundToDouble() ? v.toInt() : v.toStringAsFixed(1)}Cr';
    } else if (value >= 100000) {
      final v = value / 100000;
      return '${v == v.roundToDouble() ? v.toInt() : v.toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      final v = value / 1000;
      return '${v == v.roundToDouble() ? v.toInt() : v.toStringAsFixed(1)}k';
    } else {
      return value.toInt().toString();
    }
  }

  @override
  bool shouldRepaint(covariant _InteractiveCurveChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.touchedIndex != touchedIndex ||
        oldDelegate.chartHeight != chartHeight;
  }
}

// ── Expense Form Modal ──

class _ExpenseFormBottomSheet extends ConsumerStatefulWidget {
  final Expense? expense;
  const _ExpenseFormBottomSheet({this.expense});

  @override
  ConsumerState<_ExpenseFormBottomSheet> createState() => _ExpenseFormBottomSheetState();
}

class _ExpenseFormBottomSheetState extends ConsumerState<_ExpenseFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _vendorController;
  late TextEditingController _notesController;
  late String _selectedCategory;
  late DateTime _selectedDate;

  final List<String> _categories = [
    'Software',
    'Equipment',
    'Office',
    'Marketing',
    'Travel',
    'Utilities',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense?.title ?? '');
    _amountController = TextEditingController(
      text: widget.expense != null ? widget.expense!.amount.toStringAsFixed(2) : '',
    );
    _vendorController = TextEditingController(text: widget.expense?.paymentMethod ?? 'UPI');
    _notesController = TextEditingController(text: widget.expense?.notes ?? '');
    _selectedCategory = widget.expense?.category ?? 'Software';
    _selectedDate = widget.expense?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _vendorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final expense = Expense(
      id: widget.expense?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      amount: amount,
      category: _selectedCategory,
      date: _selectedDate,
      paymentMethod: _vendorController.text.trim().isNotEmpty ? _vendorController.text.trim() : 'UPI',
      notes: _notesController.text.trim(),
    );

    if (widget.expense != null) {
      ref.read(expenseProvider.notifier).updateExpense(expense);
    } else {
      ref.read(expenseProvider.notifier).addExpense(expense);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.expense != null ? 'Edit Expense' : 'Add New Expense',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  if (widget.expense != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                      onPressed: () {
                        ref.read(expenseProvider.notifier).deleteExpense(widget.expense!.id);
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: const InputDecoration(
                  labelText: 'Title / Description',
                  hintText: 'e.g. Figma Subscription, MacBook Pro',
                  fillColor: Color(0xFFF8FAFC),
                  filled: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 14),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: '0.00',
                  fillColor: Color(0xFFF8FAFC),
                  filled: true,
                ),
                validator: (v) => (v == null || double.tryParse(v.trim()) == null) ? 'Please enter valid amount' : null,
              ),
              const SizedBox(height: 14),

              // Category Selector
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  fillColor: Color(0xFFF8FAFC),
                  filled: true,
                ),
                items: _categories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Color(0xFF0F172A))));
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCategory = v);
                },
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    widget.expense != null ? 'Update Expense' : 'Save Expense',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
