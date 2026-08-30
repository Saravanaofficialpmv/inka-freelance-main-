import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../viewmodels/invoice_viewmodel.dart';
import '../providers/profile_provider.dart';
import 'package:inka/core/constants/colors.dart';
import '../../core/localization/app_localizations.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _showNotifications(BuildContext context, WidgetRef ref) {
    final invoices = ref.read(invoiceProvider);
    final profile = ref.read(profileProvider);
    final currencyFormat = NumberFormat.simpleCurrency(name: profile.currency, decimalDigits: 0);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)?.translate('notifications') ?? 'Notifications', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 4),
            Text('${invoices.length} invoice${invoices.length == 1 ? '' : 's'} total', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            if (invoices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.textSecondary.withOpacity(0.3)),
                      const SizedBox(height: 12),
                      const Text('No notifications yet', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              )
            else
              ...invoices.reversed.take(5).map((inv) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(inv.client.name[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Invoice for ${inv.client.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
                          Text('${currencyFormat.format(inv.total)} • ${DateFormat('dd MMM yyyy').format(inv.issueDate)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Text('Created', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
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
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final authState = ref.watch(authProvider);
    final profile = ref.watch(profileProvider);
    final currencyFormat = NumberFormat.simpleCurrency(name: profile.currency, decimalDigits: 0);

    final String displayName = profile.businessName.isNotEmpty 
      ? profile.businessName 
      : authState.when(
          data: (user) => user?.email?.split('@').first ?? 'Guest',
          loading: () => '...',
          error: (_, _) => 'Error',
        );

    return Scaffold(
      backgroundColor: AppColors.background, // #F4F4F4 soft grey
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Top App Bar ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Inka', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -1, color: Colors.black)),
                    Row(
                      children: [
                        // Notification bell → shows recent activity
                        GestureDetector(
                          onTap: () => _showNotifications(context, ref),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.notifications_none_rounded, color: Colors.black, size: 24),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => context.go('/profile'),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primary,
                            child: Text(displayName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Main Dark Portfolio Card ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard, // #141414 black
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // White text on dark card
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppLocalizations.of(context)?.translate('total_revenue') ?? 'Total Revenue', style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 16)),
                          _buildFilterSelector(context, ref),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            currencyFormat.format(stats['totalRevenue'] ?? 0).split('.').first, 
                            style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                          ),
                          const Text('.00', style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 12),
                          Text(profile.currency.toUpperCase(), style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (ref.watch(statsPeriodProvider) != StatsPeriod.allTime)
                        Row(
                          children: [
                            Icon(
                              (stats['isGrowthPositive'] as bool? ?? true) ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, 
                              color: (stats['isGrowthPositive'] as bool? ?? true) ? AppColors.success : AppColors.error, 
                              size: 16
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${((stats['revenueGrowth'] as double?) ?? 0).abs().toStringAsFixed(1)}%', 
                              style: TextStyle(
                                color: (stats['isGrowthPositive'] as bool? ?? true) ? AppColors.success : AppColors.error, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 14
                              )
                            ),
                          ],
                        ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          // Show Invoices: frosted white button on dark card
                          Expanded(
                            child: GestureDetector(
                              onTap: () => context.go('/history'),
                              child: Container(
                                height: 54,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 18),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        AppLocalizations.of(context)?.translate('invoices') ?? 'Invoices', 
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Show Clients: orange button, white text
                          Expanded(
                            child: GestureDetector(
                              onTap: () => context.push('/clients'),
                              child: Container(
                                height: 54,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.people_rounded, color: Colors.white, size: 18),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        AppLocalizations.of(context)?.translate('clients') ?? 'Clients', 
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
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
              ),
            ),

            // ── Secondary Stats Cards (white background, black text) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('/clients'),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(context)?.translate('total_clients') ?? 'Total Clients', 
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.people_rounded, color: Colors.black, size: 18),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text('${stats['totalClients'] ?? 0}', style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.go('/history'),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(context)?.translate('earnings') ?? 'Earnings', 
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.auto_graph_rounded, color: Colors.black, size: 18),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(currencyFormat.format(stats['pendingAmount'] ?? 0), style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('+ 7.0%', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                ),
              ),
            ),

            // ── History Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)?.translate('recent_invoices') ?? 'Recent Invoices', 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(onPressed: () => context.go('/history'), child: Text(AppLocalizations.of(context)?.translate('see_all') ?? 'See All')),
                  ],
                ),
              ),
            ),

            // ── Real-time Invoice History ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 140),
              sliver: _buildHistoryList(context, ref, currencyFormat),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, WidgetRef ref, NumberFormat currencyFormat) {
    final invoices = ref.watch(invoiceProvider);
    
    if (invoices.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textSecondary.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)?.translate('no_invoices') ?? 'No invoices yet', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(AppLocalizations.of(context)?.translate('create_first_invoice') ?? 'Create your first invoice to see it here', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    // Show the most recent invoices (up to 4)
    final recentInvoices = invoices.length > 4 ? invoices.sublist(invoices.length - 4).reversed.toList() : invoices.reversed.toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final invoice = recentInvoices[index];
          final dateStr = DateFormat('dd MMM').format(invoice.issueDate);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    invoice.client.name[0].toUpperCase(),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(invoice.client.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
                      Text('#${invoice.invoiceNumber.length > 6 ? invoice.invoiceNumber.substring(invoice.invoiceNumber.length - 6) : invoice.invoiceNumber}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(currencyFormat.format(invoice.total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
                    Text(dateStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ],
            ),
          );
        },
        childCount: recentInvoices.length,
      ),
    );
  }
  Widget _buildFilterSelector(BuildContext context, WidgetRef ref) {
    final currentPeriod = ref.watch(statsPeriodProvider);
    
    return PopupMenuButton<StatsPeriod>(
      initialValue: currentPeriod,
      onSelected: (period) => ref.read(statsPeriodProvider.notifier).state = period,
      color: AppColors.darkCard,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getPeriodLabel(context, currentPeriod),
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 14),
          ],
        ),
      ),
      itemBuilder: (context) => [
        _buildPopupItem(context, StatsPeriod.today, AppLocalizations.of(context)?.translate('today') ?? 'Today'),
        _buildPopupItem(context, StatsPeriod.last7Days, AppLocalizations.of(context)?.translate('last_7_days') ?? 'Last 7 Days'),
        _buildPopupItem(context, StatsPeriod.last30Days, AppLocalizations.of(context)?.translate('last_30_days') ?? 'Last 30 Days'),
        _buildPopupItem(context, StatsPeriod.allTime, AppLocalizations.of(context)?.translate('all_time') ?? 'All Time'),
      ],
    );
  }

  PopupMenuItem<StatsPeriod> _buildPopupItem(BuildContext context, StatsPeriod period, String label) {
    return PopupMenuItem(
      value: period,
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
    );
  }

  String _getPeriodLabel(BuildContext context, StatsPeriod period) {
    switch (period) {
      case StatsPeriod.today: return AppLocalizations.of(context)?.translate('today') ?? 'Today';
      case StatsPeriod.last7Days: return '7D';
      case StatsPeriod.last30Days: return '30D';
      case StatsPeriod.allTime: return AppLocalizations.of(context)?.translate('all_time') ?? 'All Time';
    }
  }
}
