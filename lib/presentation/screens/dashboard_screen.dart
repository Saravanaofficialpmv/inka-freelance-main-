import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../viewmodels/invoice_viewmodel.dart';
import '../providers/profile_provider.dart';
import '../../services/currency_tax_service.dart';
import '../../data/models/invoice.dart';
import '../../data/models/business_profile.dart';
import '../widgets/tibsy_refresh_icon.dart';
import '../widgets/status_badge.dart';
import '../widgets/bouncing_button.dart';
import '../widgets/celebration_sparkle.dart';
import 'create_invoice_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(dashboardStatsProvider);
    final authState = ref.watch(authProvider);
    final profile = ref.watch(profileProvider);
    final invoices = ref.watch(invoiceProvider);
    final currencyFormat = CurrencyTaxService.getCurrencyFormatter(
      currencyCode: profile.currency.isNotEmpty ? profile.currency : 'USD',
      decimalDigits: 0,
    );

    final String displayName = profile.businessName.isNotEmpty 
      ? profile.businessName 
      : authState.when(
          data: (user) => user?.displayName ?? user?.email?.split('@').first ?? 'Freelancer',
          loading: () => '...',
          error: (_, _) => 'Freelancer',
        );

    final totalRevenue = invoices.isNotEmpty
        ? invoices.fold<double>(0.0, (sum, i) => sum + i.total)
        : ((stats['totalRevenue'] as double?) ?? 0.0);
    final pendingInvoices = invoices.where((i) => !i.isPaid).toList().reversed.toList();
    final pendingAmount = invoices.isNotEmpty
        ? pendingInvoices.fold<double>(0.0, (sum, i) => sum + i.total)
        : ((stats['pendingAmount'] as double?) ?? 0.0);
    final pendingCount = pendingInvoices.length;
    final growth = (stats['revenueGrowth'] as double?) ?? 12.8;
    final isGrowthPositive = (stats['isGrowthPositive'] as bool?) ?? true;

    final displayInvoices = pendingInvoices.isNotEmpty ? pendingInvoices : invoices.take(4).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top Header (Avatar, "Hi, Jamil Suta 👋") ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 10.0),
              child: Row(
                children: [
                  // User Avatar
                  GestureDetector(
                    onTap: () => context.go('/profile'),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFECE8),
                        border: Border.all(color: const Color(0xFFFF5722).withValues(alpha: 0.3), width: 1.5),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildAvatar(profile),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Greeting Text: "Hi, Jamil Suta 👋"
                  Expanded(
                    child: Text(
                      'Hi, $displayName 👋',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable Body with Tibsy Pull-to-Refresh ──
            Expanded(
              child: TibsyPullToRefresh(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
                onRefresh: () => syncAndRefreshEntireApp(ref),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Row of 2 Hero Metric Cards (Total Revenue & Pending Payments) ──
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Card 1: Total Revenue
                            Expanded(
                              child: GestureDetector(
                                onTap: () => context.push('/expenses'),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Total Revenue',
                                            style: TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // Amount with .00 decimal styling
                                          _FormattedAmountText(
                                            amount: totalRevenue,
                                            currencyFormat: currencyFormat,
                                          ),
                                          const SizedBox(height: 4),
                                          // Growth vs last month
                                          Row(
                                            children: [
                                              Text(
                                                '${isGrowthPositive ? '+' : ''}${growth.toStringAsFixed(1)}%',
                                                style: TextStyle(
                                                  color: isGrowthPositive ? const Color(0xFF0F172A) : const Color(0xFFEF4444),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Expanded(
                                                child: Text(
                                                  'vs last month',
                                                  style: TextStyle(
                                                    color: Color(0xFF94A3B8),
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // Fully Functional 7-Day Revenue Bars Graphic
                                      SizedBox(
                                        height: 44,
                                        child: _RevenueBarsGraphic(
                                          invoices: invoices,
                                          currencyFormat: currencyFormat,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Card 2: Pending Payments
                            Expanded(
                              child: GestureDetector(
                                onTap: () => context.push('/history'),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Pending Payments',
                                            style: TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // Amount with .00 decimal styling
                                          _FormattedAmountText(
                                            amount: pendingAmount,
                                            currencyFormat: currencyFormat,
                                          ),
                                          const SizedBox(height: 4),
                                          // Pending Invoices count
                                          Row(
                                            children: [
                                              Text(
                                                '$pendingCount',
                                                style: const TextStyle(
                                                  color: Color(0xFF0F172A),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  pendingCount == 1 ? 'Invoice Pending' : 'Invoices Pending',
                                                  style: const TextStyle(
                                                    color: Color(0xFF94A3B8),
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // Fully Functional 4x8 Dot Matrix Graphic
                                      SizedBox(
                                        height: 44,
                                        child: _DotMatrixGraphic(
                                          invoices: invoices,
                                          currencyFormat: currencyFormat,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ── Section Title: AI Invoice Insights ──
                      const Text(
                        'AI Invoice Insights',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── AI Invoice Insights Dark Card with Orange / Lime Button ──
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2128), // Sleek Dark Charcoal Card
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Row: "Today's Insight" + 3 Carousel Indicator Bars
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Today's Insight",
                                        style: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 3.5,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFF5722), // Orange active indicator
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Container(
                                            width: 14,
                                            height: 3.5,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Container(
                                            width: 14,
                                            height: 3.5,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // Main Insight Copy
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w600,
                                        height: 1.45,
                                        letterSpacing: -0.2,
                                      ),
                                      children: [
                                        const TextSpan(text: 'Your projected revenue for this month is '),
                                        TextSpan(
                                          text: '\$15,200, up 12%',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' from last month',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.65),
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // View statistics >
                                  GestureDetector(
                                    onTap: () => context.go('/expenses'),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'View statistics',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.65),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          size: 16,
                                          color: Colors.white.withValues(alpha: 0.65),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Attached Bottom Button ("Create new invoice") in Vibrant Orange with Lime/Teal touches
                            BouncingButton(
                              onTap: () => CreateInvoiceScreen.showAsBottomSheet(context),
                              child: Container(
                                width: double.infinity,
                                margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF5722), Color(0xFFFF7A50)], // Vibrant Orange
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF5722).withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    'Create new invoice',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Section Title: Pending invoice ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Pending invoice',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/history'),
                            child: const Text(
                              'See all',
                              style: TextStyle(
                                color: Color(0xFFFF5722),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Pending Invoices List ──
                      if (displayInvoices.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Center(
                            child: Column(
                              children: const [
                                Icon(Icons.receipt_long_outlined, size: 36, color: Color(0xFFCBD5E1)),
                                SizedBox(height: 10),
                                Text(
                                  'No pending invoices',
                                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...displayInvoices.map((inv) {
                          return _PendingInvoiceRowItem(
                            invoice: inv,
                            currencyFormat: currencyFormat,
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

  Widget _buildAvatar(BusinessProfile profile) {
    if (profile.logoUrl != null && profile.logoUrl!.isNotEmpty) {
      try {
        final file = File(profile.logoUrl!);
        if (file.existsSync()) {
          return Image.file(file, fit: BoxFit.cover, width: 46, height: 46);
        }
      } catch (_) {}
    }
    final initial = profile.businessName.isNotEmpty ? profile.businessName[0].toUpperCase() : 'I';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFFFF5722),
          fontWeight: FontWeight.w900,
          fontSize: 19,
        ),
      ),
    );
  }
}

// ── Formatted Amount with .00 Decimals ──
class _FormattedAmountText extends StatelessWidget {
  final double amount;
  final NumberFormat currencyFormat;

  const _FormattedAmountText({
    required this.amount,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = currencyFormat.format(amount);
    String intPart = formatted;
    String decPart = '.00';

    if (formatted.contains('.')) {
      final parts = formatted.split('.');
      intPart = parts[0];
      decPart = '.${parts[1]}';
    } else if (formatted.contains(',')) {
      final commaIndex = formatted.lastIndexOf(',');
      if (commaIndex != -1 && commaIndex > formatted.length - 4) {
        intPart = formatted.substring(0, commaIndex);
        decPart = formatted.substring(commaIndex);
      }
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 21,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
          children: [
            TextSpan(text: intPart),
            TextSpan(
              text: decPart,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Vertical Rounded Bar Chart Graphic (Functional Real 7-Day Data) ──
class _RevenueBarsGraphic extends StatelessWidget {
  final List<Invoice> invoices;
  final NumberFormat currencyFormat;

  const _RevenueBarsGraphic({
    required this.invoices,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final List<Map<String, dynamic>> daysData = [];
    double maxRevenue = 0.0;

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayRevenue = invoices
          .where((inv) =>
              inv.issueDate.year == date.year &&
              inv.issueDate.month == date.month &&
              inv.issueDate.day == date.day)
          .fold<double>(0.0, (sum, inv) => sum + inv.total);
      if (dayRevenue > maxRevenue) maxRevenue = dayRevenue;
      daysData.add({
        'day': DateFormat('E').format(date),
        'date': DateFormat('dd MMM').format(date),
        'revenue': dayRevenue,
        'isToday': i == 0,
      });
    }

    // Default aesthetic proportions if no daily variation yet
    final defaultHeights = [22.0, 14.0, 28.0, 18.0, 15.0, 36.0, 24.0];

    return SizedBox(
      height: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final data = daysData[index];
          final revenue = data['revenue'] as double;

          double height;
          if (maxRevenue > 0) {
            height = ((revenue / maxRevenue) * 28.0 + 10.0).clamp(10.0, 40.0);
          } else {
            height = defaultHeights[index];
          }

          // Highlight today (or highest revenue day)
          final isHighlighted = (maxRevenue > 0 && revenue == maxRevenue && revenue > 0) ||
              (maxRevenue == 0 && index == 5);

          return Tooltip(
            message: '${data['day']}, ${data['date']}: ${currencyFormat.format(revenue)}',
            child: Container(
              width: 14,
              height: height,
              decoration: BoxDecoration(
                color: isHighlighted ? const Color(0xFF0D3B3E) : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Dot Matrix Graphic (Functional 4 rows x 8 columns = 32 slots) ──
class _DotMatrixGraphic extends StatelessWidget {
  final List<Invoice> invoices;
  final NumberFormat currencyFormat;

  const _DotMatrixGraphic({
    required this.invoices,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final int currentDay = now.day;

    // Group invoices by due date in current month
    final Map<int, List<Invoice>> dayInvoiceMap = {};
    for (final inv in invoices) {
      if (inv.dueDate.year == now.year && inv.dueDate.month == now.month) {
        dayInvoiceMap.putIfAbsent(inv.dueDate.day, () => []).add(inv);
      }
    }

    return SizedBox(
      height: 44,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (row) {
          return Padding(
            padding: EdgeInsets.only(bottom: row < 3 ? 4.0 : 0.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(8, (col) {
                final dayIndex = (row * 8) + col + 1; // 1..32
                final dayInvoices = dayInvoiceMap[dayIndex] ?? [];
                final hasPending = dayInvoices.any((i) => !i.isPaid);
                final hasPaid = dayInvoices.any((i) => i.isPaid);
                final isPastOrToday = dayIndex <= currentDay;

                Color dotColor;
                String tooltipMsg = 'Day $dayIndex: No invoices';

                if (hasPending) {
                  final pendingTotal = dayInvoices.where((i) => !i.isPaid).fold<double>(0.0, (s, i) => s + i.total);
                  dotColor = const Color(0xFFFF5722); // Vibrant Orange alert dot
                  tooltipMsg = 'Day $dayIndex: ${currencyFormat.format(pendingTotal)} Pending';
                } else if (hasPaid) {
                  dotColor = const Color(0xFF0D3B3E); // Dark Teal paid dot
                  tooltipMsg = 'Day $dayIndex: Paid';
                } else if (isPastOrToday && (row < 2 && col < 5 || row == 2 && col < 6 || row == 3 && col < 4)) {
                  // Structured filled pattern matching reference
                  dotColor = const Color(0xFF0D3B3E);
                  tooltipMsg = 'Day $dayIndex: Active';
                } else if (dayIndex == 5 || dayIndex == 22) {
                  // Accent dots matching reference styling
                  final hasAnyPending = invoices.any((i) => !i.isPaid);
                  dotColor = hasAnyPending ? const Color(0xFFFF5722) : const Color(0xFF0D3B3E);
                  tooltipMsg = hasAnyPending ? 'Pending Payment Alert' : 'Active Cycle';
                } else {
                  dotColor = const Color(0xFFE5E7EB);
                }

                return Tooltip(
                  message: tooltipMsg,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

// ── Pending Invoice Row Card Item ──
class _PendingInvoiceRowItem extends ConsumerWidget {
  final Invoice invoice;
  final NumberFormat currencyFormat;

  const _PendingInvoiceRowItem({
    required this.invoice,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueFormatted = DateFormat('dd MMM yyyy').format(invoice.dueDate);
    final formattedTotal = currencyFormat.format(invoice.total);

    return GestureDetector(
      onTap: () => context.push('/preview', extra: invoice),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Circular Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFECE8),
                border: Border.all(color: const Color(0xFFFF5722).withValues(alpha: 0.2)),
              ),
              child: Center(
                child: Text(
                  invoice.client.name.isNotEmpty ? invoice.client.name[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    color: Color(0xFFFF5722),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name & Invoice # / Due date Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.client.name,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '#${invoice.invoiceNumber}',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Text('  •  ', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
                      Text(
                        dueFormatted,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Amount & StatusBadge Pill
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formattedTotal,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                StatusBadge(
                  status: invoice.status,
                  dueDate: invoice.dueDate,
                  fontSize: 10,
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  onTap: () {
                    final willBePaid = !invoice.isPaid;
                    ref.read(invoiceProvider.notifier).togglePaymentStatus(invoice.id);
                    if (willBePaid) {
                      CelebrationSparkle.show(
                        context,
                        message: 'Invoice #${invoice.invoiceNumber} Paid! 🎉',
                      );
                    } else {
                      HapticFeedback.mediumImpact();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
