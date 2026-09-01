import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../viewmodels/invoice_viewmodel.dart';
import '../providers/profile_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/currency_tax_service.dart';
import '../../services/firestore_service.dart';
import '../../data/models/invoice.dart';
import 'create_invoice_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showNotifications(BuildContext context, WidgetRef ref) {
    final invoices = ref.read(invoiceProvider);
    final profile = ref.read(profileProvider);
    final currencyFormat = CurrencyTaxService.getCurrencyFormatter(
      currencyCode: profile.currency.isNotEmpty ? profile.currency : 'USD',
      decimalDigits: 0,
    );

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)?.translate('notifications') ?? 'Notifications',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                Text(
                  '${invoices.length} total',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (invoices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: const [
                      Icon(Icons.notifications_off_outlined, size: 44, color: Color(0xFFCBD5E1)),
                      SizedBox(height: 12),
                      Text('No notifications yet', style: TextStyle(color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              )
            else
              ...invoices.reversed.take(4).map((inv) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          inv.client.name.isNotEmpty ? inv.client.name[0].toUpperCase() : 'C',
                          style: const TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invoice for ${inv.client.name}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            '${currencyFormat.format(inv.total)} • ${DateFormat('dd MMM yyyy').format(inv.issueDate)}',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Created',
                        style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
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

    final String displayName = profile.businessName.isNotEmpty 
      ? profile.businessName 
      : authState.when(
          data: (user) => user?.displayName ?? user?.email?.split('@').first ?? 'Jamil Suta',
          loading: () => '...',
          error: (_, _) => 'Jamil Suta',
        );

    final totalRevenue = (stats['totalRevenue'] as double?) ?? 24000.0;
    final pendingAmount = (stats['pendingAmount'] as double?) ?? 5670.0;
    final pendingInvoices = invoices.where((i) => !i.isPaid).toList().reversed.toList();
    final pendingCount = pendingInvoices.isNotEmpty ? pendingInvoices.length : 24;

    // Filter pending invoices if search query is active
    final displayInvoices = _searchQuery.isEmpty 
        ? (pendingInvoices.isNotEmpty ? pendingInvoices : invoices.take(4).toList())
        : invoices.where((inv) => 
            inv.client.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            inv.invoiceNumber.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top Header (Avatar, "Hi, Jamil Suta 👋", Search icon, Notification bell) ──
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
                        image: const DecorationImage(
                          image: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80'),
                          fit: BoxFit.cover,
                        ),
                      ),
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

                  // Search Icon Button
                  GestureDetector(
                    onTap: () => setState(() => _isSearching = !_isSearching),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.search_rounded, color: Color(0xFF1E293B), size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Notification Bell with Orange Dot
                  GestureDetector(
                    onTap: () => _showNotifications(context, ref),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.notifications_none_rounded, color: Color(0xFF1E293B), size: 20),
                          Positioned(
                            top: 10,
                            right: 11,
                            child: Container(
                              width: 6.5,
                              height: 6.5,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF5722), // Orange Notification Dot
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar (Expandable)
            if (_isSearching)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          autofocus: true,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13.5),
                          decoration: const InputDecoration(
                            hintText: 'Search invoices, clients...',
                            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            filled: false,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
                        ),
                    ],
                  ),
                ),
              ),

            // ── Scrollable Body with Pull-to-Refresh ──
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFFFF5722),
                backgroundColor: Colors.white,
                onRefresh: () async {
                  final user = ref.read(authProvider).value;
                  if (user != null) {
                    try {
                      final firestoreService = ref.read(firestoreServiceProvider);
                      await firestoreService.syncAllData(user.uid);
                    } catch (_) {}
                  }
                  ref.read(invoiceProvider.notifier).refreshFromLocal();
                  ref.read(profileProvider.notifier).loadFromLocal();
                  await Future.delayed(const Duration(milliseconds: 300));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Row of 2 Hero Metric Cards (Total Revenue & Pending Payments) ──
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card 1: Total Revenue
                          Expanded(
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
                                children: [
                                  const Text(
                                    'Total Revenue',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  // Amount with .00 decimal styling
                                  _FormattedAmountText(
                                    amount: totalRevenue,
                                    currencyFormat: currencyFormat,
                                  ),
                                  const SizedBox(height: 4),
                                  // 12.8% than last month
                                  Row(
                                    children: const [
                                      Text(
                                        '12.8%',
                                        style: TextStyle(
                                          color: Color(0xFF0F172A),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'than last month',
                                          style: TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 10.5,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Rounded Bar Chart Graphic with highlighted Dark Teal/Orange bar
                                  const _RevenueBarsGraphic(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Card 2: Pending Payments
                          Expanded(
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
                                children: [
                                  const Text(
                                    'Pending Payments',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  // Amount with .00 decimal styling
                                  _FormattedAmountText(
                                    amount: pendingAmount,
                                    currencyFormat: currencyFormat,
                                  ),
                                  const SizedBox(height: 4),
                                  // 24 Invoice Pending
                                  Row(
                                    children: [
                                      Text(
                                        '$pendingCount',
                                        style: const TextStyle(
                                          color: Color(0xFF0F172A),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Invoice Pending',
                                        style: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 10.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Dot Matrix Grid Graphic
                                  const _DotMatrixGraphic(),
                                ],
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
                            GestureDetector(
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
            ),
          ],
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
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 21,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        children: [
          TextSpan(text: formatted),
          const TextSpan(
            text: '.00',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vertical Rounded Bar Chart Graphic ──
class _RevenueBarsGraphic extends StatelessWidget {
  const _RevenueBarsGraphic();

  @override
  Widget build(BuildContext context) {
    // 7 vertical bars with heights and 1 dark highlighted bar (matching reference)
    final bars = [
      {'height': 24.0, 'color': const Color(0xFFE5E7EB)},
      {'height': 14.0, 'color': const Color(0xFFE5E7EB)},
      {'height': 30.0, 'color': const Color(0xFFE5E7EB)},
      {'height': 20.0, 'color': const Color(0xFFE5E7EB)},
      {'height': 16.0, 'color': const Color(0xFFE5E7EB)},
      {'height': 38.0, 'color': const Color(0xFF0D3B3E)}, // Dark highlighted bar
      {'height': 26.0, 'color': const Color(0xFFE5E7EB)},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: bars.map((b) {
        return Container(
          width: 14,
          height: b['height'] as double,
          decoration: BoxDecoration(
            color: b['color'] as Color,
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }).toList(),
    );
  }
}

// ── Dot Matrix Graphic (4 rows x 8 columns) ──
class _DotMatrixGraphic extends StatelessWidget {
  const _DotMatrixGraphic();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(4, (row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 5.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(8, (col) {
              // Highlighted dark dots vs lighter gray dots
              final isFilled = (row < 2 && col < 5) || (row == 2 && col < 6) || (row == 3 && col < 4);
              final isOrangeAccent = (row == 0 && col == 4) || (row == 2 && col == 5);
              return Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isOrangeAccent 
                      ? const Color(0xFFFF5722) 
                      : (isFilled ? const Color(0xFF0D3B3E) : const Color(0xFFE5E7EB)),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

// ── Pending Invoice Row Card Item ──
class _PendingInvoiceRowItem extends StatelessWidget {
  final Invoice invoice;
  final NumberFormat currencyFormat;

  const _PendingInvoiceRowItem({
    required this.invoice,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final status = invoice.isPaid ? 'Paid' : 'Viewed';
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
            const SizedBox(width: 14),

            // Name & Status Subtitle (#7819090 • Viewed)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.client.name,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '#${invoice.invoiceNumber}',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        status,
                        style: TextStyle(
                          color: invoice.isPaid ? const Color(0xFF10B981) : const Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Amount ($2,400.00) & Due Date (Until 27 Aug 2025)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                    children: [
                      TextSpan(text: formattedTotal),
                      const TextSpan(
                        text: '.00',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Until $dueFormatted',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
