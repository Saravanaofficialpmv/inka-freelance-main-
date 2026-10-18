import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../viewmodels/invoice_viewmodel.dart';
import '../providers/profile_provider.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/theme_helper.dart';
import '../../services/currency_tax_service.dart';
import '../../data/models/invoice.dart';
import '../../data/models/business_profile.dart';
import '../widgets/tibsy_refresh_icon.dart';
import '../widgets/status_badge.dart';
import '../widgets/bouncing_button.dart';
import '../widgets/celebration_sparkle.dart';
import '../widgets/animated_currency_text.dart';
import '../../core/theme/app_motion.dart';
import 'create_invoice_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isGridView = false;
  String _selectedTimeframe = 'all'; // 'all', 'month', '90d', 'week'

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  String _getFirstName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Freelancer';
    return trimmed.split(' ').first;
  }

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

    final user = authState.value;
    final String displayName = profile.businessName.isNotEmpty 
      ? profile.businessName 
      : authState.when(
          data: (user) => user?.displayName ?? user?.email?.split('@').first ?? 'Freelancer',
          loading: () => '...',
          error: (_, _) => 'Freelancer',
        );

    final now = DateTime.now();
    List<Invoice> timeframeInvoices;
    switch (_selectedTimeframe) {
      case 'week':
        final cutoff = now.subtract(const Duration(days: 7));
        timeframeInvoices = invoices.where((i) => i.issueDate.isAfter(cutoff)).toList();
        break;
      case 'month':
        final cutoff = DateTime(now.year, now.month, 1);
        timeframeInvoices = invoices
            .where((i) => i.issueDate.isAfter(cutoff.subtract(const Duration(seconds: 1))))
            .toList();
        break;
      case '90d':
        final cutoff = now.subtract(const Duration(days: 90));
        timeframeInvoices = invoices.where((i) => i.issueDate.isAfter(cutoff)).toList();
        break;
      case 'all':
      default:
        timeframeInvoices = invoices;
        break;
    }

    final totalRevenue = timeframeInvoices.isNotEmpty
        ? timeframeInvoices.fold<double>(0.0, (sum, i) => sum + i.total)
        : ((stats['totalRevenue'] as double?) ?? 0.0);
    final paidInvoices = timeframeInvoices.where((i) => i.isPaid).toList();
    final paidAmount = paidInvoices.fold<double>(0.0, (sum, i) => sum + i.total);
    final pendingInvoices = timeframeInvoices.where((i) => !i.isPaid).toList().reversed.toList();
    final pendingAmount = timeframeInvoices.isNotEmpty
        ? pendingInvoices.fold<double>(0.0, (sum, i) => sum + i.total)
        : ((stats['pendingAmount'] as double?) ?? 0.0);
    final pendingCount = pendingInvoices.length;
    final overdueInvoices =
        timeframeInvoices.where((i) => !i.isPaid && i.dueDate.isBefore(now)).toList();
    final overdueAmount = overdueInvoices.fold<double>(0.0, (sum, i) => sum + i.total);

    final growth = (stats['revenueGrowth'] as double?) ?? 12.8;
    final isGrowthPositive = (stats['isGrowthPositive'] as bool?) ?? true;

    final displayInvoices = pendingInvoices.isNotEmpty ? pendingInvoices : timeframeInvoices.take(4).toList();
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    if (isWide) {
      return _buildWebDashboard(
        context: context,
        displayName: displayName,
        invoices: timeframeInvoices,
        currencyFormat: currencyFormat,
        totalRevenue: totalRevenue,
        paidAmount: paidAmount,
        pendingAmount: pendingAmount,
        pendingCount: pendingCount,
        overdueInvoices: overdueInvoices,
        overdueAmount: overdueAmount,
        growth: growth,
        isGrowthPositive: isGrowthPositive,
      );
    }

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header ──
            if (isWide)
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 22.0, 24.0, 14.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, $displayName 👋',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Here's an overview of your invoices and business activity.",
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: context.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('EEEE, d MMMM').format(DateTime.now()),
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
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
                        child: _buildAvatar(profile, user),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Greeting Text: "Hi, Jamil Suta 👋"
                    Expanded(
                      child: Text(
                        'Hi, $displayName 👋',
                        style: TextStyle(
                          color: context.textPrimary,
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
                padding: EdgeInsets.fromLTRB(isWide ? 24 : 20, 8, isWide ? 24 : 20, isWide ? 32 : 140),
                onRefresh: () => syncAndRefreshEntireApp(ref),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Timeframe Filter Chips Bar ──
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildTimeframeChip('all', 'All Time'),
                            const SizedBox(width: 8),
                            _buildTimeframeChip('month', 'This Month'),
                            const SizedBox(width: 8),
                            _buildTimeframeChip('90d', '90 Days'),
                            const SizedBox(width: 8),
                            _buildTimeframeChip('week', 'This Week'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Row of 2 Hero Metric Cards (Total Revenue & Pending Payments) ──
                      StaggeredSlideFade(
                        index: 0,
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Card 1: Total Revenue
                              Expanded(
                                child: BouncingButton(
                                  scaleFactor: 0.98,
                                  onTap: () => context.push('/history', extra: 'Paid'),
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
                                          invoices: timeframeInvoices,
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
                              child: BouncingButton(
                                scaleFactor: 0.98,
                                onTap: () => context.push('/history', extra: 'Unpaid'),
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
                                          invoices: timeframeInvoices,
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
                    ),

                    const SizedBox(height: 12),

                    // ── Sub-Metrics: Collected Revenue & Overdue Invoices ──
                    Row(
                      children: [
                        Expanded(
                          child: BouncingButton(
                            onTap: () => context.push('/history', extra: 'Paid'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF10B981)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Collected',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF64748B),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          currencyFormat.format(paidAmount),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: BouncingButton(
                            onTap: () => context.push('/history', extra: 'Unpaid'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: (overdueInvoices.isNotEmpty ? const Color(0xFFEF4444) : const Color(0xFF94A3B8)).withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.alarm_rounded, size: 16, color: overdueInvoices.isNotEmpty ? const Color(0xFFEF4444) : const Color(0xFF94A3B8)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          overdueInvoices.isNotEmpty ? '${overdueInvoices.length} Overdue' : 'Overdue',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: overdueInvoices.isNotEmpty ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          currencyFormat.format(overdueAmount),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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
                      StaggeredSlideFade(
                        index: 1,
                        child: Container(
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
                        child: isWide
                            ? Padding(
                                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                "Today's Insight",
                                                style: TextStyle(
                                                  color: Color(0xFF94A3B8),
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Container(
                                                width: 24,
                                                height: 3.5,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFF5722),
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
                                          const SizedBox(height: 10),
                                          const Text(
                                            'Your projected revenue for this month is \$15,200, up 12% from last month',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          GestureDetector(
                                            onTap: () => context.go('/expenses'),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'View statistics',
                                                  style: TextStyle(
                                                    color: Color(0xFFFF7A50),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                SizedBox(width: 4),
                                                Icon(
                                                  Icons.chevron_right_rounded,
                                                  size: 16,
                                                  color: Color(0xFFFF7A50),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    BouncingButton(
                                      onTap: () => CreateInvoiceScreen.showAsBottomSheet(context),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFFFF5722), Color(0xFFFF7A50)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFFF5722).withValues(alpha: 0.35),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.add_rounded, color: Colors.white, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              'Create new invoice',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
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
                                              const TextSpan(
                                                text: '\$15,200, up 12%',
                                                style: TextStyle(
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
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'View statistics',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              SizedBox(width: 4),
                                              Icon(
                                                Icons.chevron_right_rounded,
                                                size: 16,
                                                color: Colors.white,
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

  Widget _buildTimeframeChip(String key, String label) {
    final isSelected = _selectedTimeframe == key;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedTimeframe = key);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E2128) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E2128) : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BusinessProfile profile, [User? user]) {
    final logo = profile.logoUrl?.trim();
    if (logo != null && logo.isNotEmpty) {
      if (logo.startsWith('http://') || logo.startsWith('https://')) {
        return Image.network(
          logo,
          fit: BoxFit.cover,
          width: 46,
          height: 46,
          errorBuilder: (context, error, stackTrace) => _buildUserPhotoOrInitial(user, profile),
        );
      } else if (!kIsWeb) {
        try {
          final file = File(logo);
          if (file.existsSync()) {
            return Image.file(file, fit: BoxFit.cover, width: 46, height: 46);
          }
        } catch (_) {}
      }
    }
    return _buildUserPhotoOrInitial(user, profile);
  }

  Widget _buildUserPhotoOrInitial(User? user, BusinessProfile profile) {
    final photo = user?.photoURL?.trim();
    if (photo != null && photo.isNotEmpty) {
      return Image.network(
        photo,
        fit: BoxFit.cover,
        width: 46,
        height: 46,
        errorBuilder: (context, error, stackTrace) => _buildInitialAvatar(profile),
      );
    }
    return _buildInitialAvatar(profile);
  }

  Widget _buildInitialAvatar(BusinessProfile profile) {
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

  // ─────────────────────────────────────────────────────────────
  // ── MIRO-INSPIRED DESKTOP WEB DASHBOARD ──────────────────────
  // ─────────────────────────────────────────────────────────────

  Widget _buildWebDashboard({
    required BuildContext context,
    required String displayName,
    required List<Invoice> invoices,
    required NumberFormat currencyFormat,
    required double totalRevenue,
    required double paidAmount,
    required double pendingAmount,
    required int pendingCount,
    required List<Invoice> overdueInvoices,
    required double overdueAmount,
    required double growth,
    required bool isGrowthPositive,
  }) {
    return Material(
      color: const Color(0xFFF7F8FA),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Editorial Hero Greeting & Live Date Badge ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 32, 40, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_getGreeting()}, ${_getFirstName(displayName)}',
                              style: TextStyle(
                                fontFamily: 'SpaceGrotesk',
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Welcome to your invoicing workspace. Here's a real-time overview of your revenue, cash flow, and recent activity.",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── 2. Timeframe Filter Chips Bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    children: [
                      _buildTimeframeChip('all', 'All Time'),
                      const SizedBox(width: 8),
                      _buildTimeframeChip('month', 'This Month'),
                      const SizedBox(width: 8),
                      _buildTimeframeChip('90d', '90 Days'),
                      const SizedBox(width: 8),
                      _buildTimeframeChip('week', 'This Week'),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ── 3. Financial Hero Metric Cards ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Card 1: Total Revenue
                            Expanded(
                              child: BouncingButton(
                                scaleFactor: 0.98,
                                onTap: () => context.push('/history', extra: 'Paid'),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
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
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Flexible(
                                                child: Text(
                                                  'Total Revenue',
                                                  style: TextStyle(
                                                    color: Color(0xFF64748B),
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: (isGrowthPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      isGrowthPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                                      size: 13,
                                                      color: isGrowthPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      '${isGrowthPositive ? '+' : ''}${growth.toStringAsFixed(1)}%',
                                                      style: TextStyle(
                                                        color: isGrowthPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          _FormattedAmountText(
                                            amount: totalRevenue,
                                            currencyFormat: currencyFormat,
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Cumulative revenue for selected period',
                                            style: TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 18),
                                      SizedBox(
                                        height: 48,
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

                            const SizedBox(width: 16),

                            // Card 2: Pending Payments
                            Expanded(
                              child: BouncingButton(
                                scaleFactor: 0.98,
                                onTap: () => context.push('/history', extra: 'Unpaid'),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
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
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Flexible(
                                                child: Text(
                                                  'Pending Payments',
                                                  style: TextStyle(
                                                    color: Color(0xFF64748B),
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '$pendingCount ${pendingCount == 1 ? 'invoice' : 'invoices'}',
                                                  style: const TextStyle(
                                                    color: AppColors.primary,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          _FormattedAmountText(
                                            amount: pendingAmount,
                                            currencyFormat: currencyFormat,
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Awaiting settlement from clients',
                                            style: TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 18),
                                      SizedBox(
                                        height: 48,
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

                      const SizedBox(height: 14),

                      // Sub-Metrics: Collected & Overdue
                      Row(
                        children: [
                          Expanded(
                            child: BouncingButton(
                              scaleFactor: 0.98,
                              onTap: () => context.push('/history', extra: 'Paid'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check_circle_outline_rounded, size: 20, color: Color(0xFF10B981)),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Collected Revenue',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            currencyFormat.format(paidAmount),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF0F172A),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: BouncingButton(
                              scaleFactor: 0.98,
                              onTap: () => context.push('/history', extra: 'Unpaid'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: (overdueInvoices.isNotEmpty ? const Color(0xFFEF4444) : const Color(0xFF94A3B8)).withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.alarm_rounded,
                                        size: 20,
                                        color: overdueInvoices.isNotEmpty ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            overdueInvoices.isNotEmpty ? '${overdueInvoices.length} Overdue Invoices' : 'Overdue Invoices',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: overdueInvoices.isNotEmpty ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            currencyFormat.format(overdueAmount),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF0F172A),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ── 4. AI Invoice Insights Banner ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2128),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompactBanner = constraints.maxWidth < 650;
                        final content = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                const Text(
                                  'AI Financial Insights',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'PRO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              overdueInvoices.isNotEmpty
                                  ? 'You have ${overdueInvoices.length} overdue invoices totaling ${currencyFormat.format(overdueAmount)}. Send 1-tap WhatsApp payment reminders to accelerate settlement.'
                                  : pendingAmount > 0
                                      ? 'Healthy cash flow forecast. ${currencyFormat.format(pendingAmount)} is scheduled for settlement across $pendingCount invoices this cycle.'
                                      : 'All invoices settled! You have a 100% collection rate. Ready to create your next project invoice?',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        );

                        final actionButton = ElevatedButton.icon(
                          onPressed: () => context.push('/history', extra: overdueInvoices.isNotEmpty ? 'Unpaid' : null),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 15, color: Color(0xFF1E2128)),
                          label: const Text(
                            'Review Invoices',
                            style: TextStyle(
                              color: Color(0xFF1E2128),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1E2128),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        );

                        if (isCompactBanner) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: content),
                                ],
                              ),
                              const SizedBox(height: 14),
                              actionButton,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: content),
                            const SizedBox(width: 20),
                            actionButton,
                          ],
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── 5. "Start something new" Section ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start something new',
                              style: TextStyle(
                                fontFamily: 'SpaceGrotesk',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Create a blank invoice or choose from pre-built professional templates',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => CreateInvoiceScreen.showAsBottomSheet(context),
                        icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                        label: const Text(
                          'Create',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Horizontal Card Deck
                SizedBox(
                  height: 185,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    children: [
                      // Card 1: Blank invoice
                      InkWell(
                        onTap: () => CreateInvoiceScreen.showAsBottomSheet(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 170,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border, width: 1.2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.iconBg,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.add_rounded, size: 24, color: AppColors.primary),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Blank invoice',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Start from scratch',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Card 2: Standard Invoice (Inka Orange)
                      _buildTemplateCard(
                        context: context,
                        title: 'Standard Invoice',
                        subtitle: 'Quick & itemized',
                        tag: 'Popular',
                        accentColor: AppColors.primary,
                        previewTotal: 3500.0,
                        currencyFormat: currencyFormat,
                      ),

                      const SizedBox(width: 14),

                      // Card 3: Consulting
                      _buildTemplateCard(
                        context: context,
                        title: 'Consulting Invoice',
                        subtitle: 'Hourly & retainers',
                        tag: 'Hourly',
                        accentColor: const Color(0xFF2563EB),
                        previewTotal: 4500.0,
                        currencyFormat: currencyFormat,
                      ),

                      const SizedBox(width: 14),

                      // Card 4: Design & Creative
                      _buildTemplateCard(
                        context: context,
                        title: 'Design & Creative',
                        subtitle: 'Deliverable milestones',
                        tag: 'Milestone',
                        accentColor: const Color(0xFF8B5CF6),
                        previewTotal: 2800.0,
                        currencyFormat: currencyFormat,
                      ),

                      const SizedBox(width: 14),

                      // Card 5: Software Dev
                      _buildTemplateCard(
                        context: context,
                        title: 'Software Dev',
                        subtitle: 'Sprint & tech consulting',
                        tag: 'Sprint',
                        accentColor: const Color(0xFF10B981),
                        previewTotal: 8200.0,
                        currencyFormat: currencyFormat,
                      ),

                      const SizedBox(width: 14),

                      // Card 6: Tax Compliant
                      _buildTemplateCard(
                        context: context,
                        title: 'Tax Compliant',
                        subtitle: 'Itemized with tax totals',
                        tag: 'GST / VAT',
                        accentColor: AppColors.accentOrange,
                        previewTotal: 950.0,
                        currencyFormat: currencyFormat,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // ── 3. "Jump back to recents" Section ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jump back to recents',
                              style: TextStyle(
                                fontFamily: 'SpaceGrotesk',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Recently edited and issued invoices',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildViewToggleButton(
                              icon: Icons.view_headline_rounded,
                              tooltip: 'List view',
                              isSelected: !_isGridView,
                              onTap: () => setState(() => _isGridView = false),
                            ),
                            _buildViewToggleButton(
                              icon: Icons.grid_view_rounded,
                              tooltip: 'Grid view',
                              isSelected: _isGridView,
                              onTap: () => setState(() => _isGridView = true),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Invoices Table, Grid or Empty State
                if (invoices.isEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.iconBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            child: const Icon(Icons.receipt_long_outlined, size: 28, color: AppColors.primary),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No invoices created yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Pick a template above or create your first invoice to get started.',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => CreateInvoiceScreen.showAsBottomSheet(context),
                            icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                            label: const Text(
                              'Create First Invoice',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (!_isGridView)
                  // Table / List View
                  Container(
                    margin: const EdgeInsets.fromLTRB(40, 10, 40, 48),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.015),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          color: const Color(0xFFF9FAFB),
                          child: const Row(
                            children: [
                              Expanded(flex: 3, child: Text('NAME / INVOICE #', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280), letterSpacing: 0.4))),
                              Expanded(flex: 2, child: Text('CLIENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280), letterSpacing: 0.4))),
                              Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280), letterSpacing: 0.4))),
                              Expanded(flex: 2, child: Text('AMOUNT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280), letterSpacing: 0.4))),
                              Expanded(flex: 2, child: Text('DATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280), letterSpacing: 0.4))),
                              SizedBox(width: 80, child: Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280), letterSpacing: 0.4))),
                            ],
                          ),
                        ),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F3F5)),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: invoices.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1, color: Color(0xFFF1F3F5)),
                          itemBuilder: (context, index) {
                            final invoice = invoices[index];
                            return _buildInvoiceTableRow(context, invoice, currencyFormat);
                          },
                        ),
                      ],
                    ),
                  )
                else
                  // Grid View
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 10, 40, 48),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 800 ? 3 : 2;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.45,
                          ),
                          itemCount: invoices.length,
                          itemBuilder: (context, index) {
                            final invoice = invoices[index];
                            return _buildInvoiceGridCard(context, invoice, currencyFormat);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required String tooltip,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String tag,
    required Color accentColor,
    required double previewTotal,
    required NumberFormat currencyFormat,
  }) {
    return InkWell(
      onTap: () => CreateInvoiceScreen.showAsBottomSheet(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 175,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top document preview thumbnail
            Expanded(
              child: Container(
                color: const Color(0xFFF9FAFB),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 4,
                      width: 32,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 5,
                      width: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 4,
                      width: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 4,
                      width: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 9.0,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          currencyFormat.format(previewTotal),
                          style: const TextStyle(
                            fontSize: 10.0,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F3F5)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceTableRow(BuildContext context, Invoice invoice, NumberFormat currencyFormat) {
    return InkWell(
      onTap: () => context.push('/preview', extra: invoice),
      hoverColor: const Color(0xFFF9FAFB),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Name / Invoice #
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.iconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.description_outlined, size: 18, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${invoice.invoiceNumber}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (invoice.notes.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            invoice.notes,
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Client
            Expanded(
              flex: 2,
              child: Text(
                invoice.client.name.isNotEmpty ? invoice.client.name : 'No client',
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Status
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildWebStatusPill(invoice.status),
              ),
            ),
            // Amount
            Expanded(
              flex: 2,
              child: Text(
                currencyFormat.format(invoice.total),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
            // Date
            Expanded(
              flex: 2,
              child: Text(
                DateFormat('MMM d, yyyy').format(invoice.issueDate),
                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
            ),
            // Actions
            SizedBox(
              width: 80,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.textSecondary),
                    tooltip: 'Preview',
                    splashRadius: 16,
                    onPressed: () => context.push('/preview', extra: invoice),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                    tooltip: 'Edit',
                    splashRadius: 16,
                    onPressed: () => CreateInvoiceScreen.showAsBottomSheet(context, invoiceToEdit: invoice),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceGridCard(BuildContext context, Invoice invoice, NumberFormat currencyFormat) {
    return InkWell(
      onTap: () => context.push('/preview', extra: invoice),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Accent Header
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              color: const Color(0xFFF9FAFB),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        '#${invoice.invoiceNumber}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  _buildWebStatusPill(invoice.status),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F3F5)),
            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.client.name.isNotEmpty ? invoice.client.name : 'No client',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, yyyy').format(invoice.issueDate),
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormat.format(invoice.total),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                              onPressed: () => CreateInvoiceScreen.showAsBottomSheet(context, invoiceToEdit: invoice),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                              splashRadius: 14,
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.primary),
                              onPressed: () => context.push('/preview', extra: invoice),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                              splashRadius: 14,
                            ),
                          ],
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
    );
  }

  Widget _buildWebStatusPill(String status) {
    Color bg;
    Color fg;
    String label;
    switch (status.toLowerCase()) {
      case 'paid':
        bg = AppColors.successBg;
        fg = AppColors.success;
        label = 'Paid';
        break;
      case 'overdue':
        bg = AppColors.errorBg;
        fg = AppColors.error;
        label = 'Overdue';
        break;
      case 'pending':
      default:
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        label = 'Pending';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}


// ── Formatted Amount with .00 Decimals & Animated Rolling Numbers ──
class _FormattedAmountText extends StatelessWidget {
  final double amount;
  final NumberFormat currencyFormat;

  const _FormattedAmountText({
    required this.amount,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedFormattedAmount(
      amount: amount,
      currencyFormat: currencyFormat,
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
            child: AnimatedContainer(
              duration: AppMotion.numberTransition,
              curve: AppMotion.entrance,
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
                  child: AnimatedContainer(
                    duration: AppMotion.standard,
                    curve: AppMotion.stateChange,
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
