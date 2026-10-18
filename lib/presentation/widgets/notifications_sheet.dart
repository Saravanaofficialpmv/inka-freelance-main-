import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/invoice.dart';
import '../providers/sync_status_provider.dart';
import '../providers/profile_provider.dart';
import '../viewmodels/invoice_viewmodel.dart';
import '../../services/currency_tax_service.dart';
import 'bouncing_button.dart';
import 'tibsy_refresh_icon.dart';
import 'share_invoice_bottom_sheet.dart';

class NotificationsSheet extends ConsumerWidget {
  const NotificationsSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const NotificationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(invoiceProvider);
    final syncState = ref.watch(syncStatusProvider);
    final profile = ref.watch(profileProvider);

    final currencyFormat = CurrencyTaxService.getCurrencyFormatter(
      currencyCode: profile.currency.isNotEmpty ? profile.currency : 'USD',
      decimalDigits: 0,
    );

    final now = DateTime.now();

    // Overdue invoices
    final overdueInvoices = invoices.where((i) {
      return !i.isPaid && i.dueDate.isBefore(now);
    }).toList();

    // Due soon (within next 5 days)
    final dueSoonInvoices = invoices.where((i) {
      if (i.isPaid) return false;
      final diff = i.dueDate.difference(now).inDays;
      return diff >= 0 && diff <= 5;
    }).toList();

    // Recently paid (last 7 days)
    final recentlyPaidInvoices = invoices.where((i) {
      return i.isPaid && now.difference(i.dueDate).inDays <= 7;
    }).take(3).toList();

    final hasAnyNotification = overdueInvoices.isNotEmpty ||
        dueSoonInvoices.isNotEmpty ||
        recentlyPaidInvoices.isNotEmpty;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag Handle ──
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Header Bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECE8),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFF5722).withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.notifications_active_outlined, size: 19, color: Color(0xFFFF5722)),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications & Activity',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Real-time invoice alerts & cloud sync',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
                BouncingButton(
                  scaleFactor: 0.90,
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(Icons.close_rounded, size: 17, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // ── Scrollable Body ──
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. Cloud Sync Health Card ──
                  _buildSyncCard(context, ref, syncState),
                  const SizedBox(height: 16),

                  if (!hasAnyNotification) ...[
                    // Empty notifications state
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.done_all_rounded, size: 38, color: Color(0xFF10B981)),
                          SizedBox(height: 10),
                          Text(
                            'All caught up!',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'No pending invoice alerts, overdue payments, or sync conflicts.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // ── 2. Overdue Alerts ──
                    if (overdueInvoices.isNotEmpty) ...[
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'OVERDUE PAYMENTS (${overdueInvoices.length})',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFEF4444),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...overdueInvoices.map((inv) => _buildInvoiceAlertItem(
                            context: context,
                            invoice: inv,
                            currencyFormat: currencyFormat,
                            isOverdue: true,
                            profile: profile,
                          )),
                      const SizedBox(height: 16),
                    ],

                    // ── 3. Due Soon Alerts ──
                    if (dueSoonInvoices.isNotEmpty) ...[
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'DUE SOON (${dueSoonInvoices.length})',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFF59E0B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...dueSoonInvoices.map((inv) => _buildInvoiceAlertItem(
                            context: context,
                            invoice: inv,
                            currencyFormat: currencyFormat,
                            isOverdue: false,
                            profile: profile,
                          )),
                      const SizedBox(height: 16),
                    ],

                    // ── 4. Recently Paid Activity ──
                    if (recentlyPaidInvoices.isNotEmpty) ...[
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'RECENT COLLECTIONS (${recentlyPaidInvoices.length})',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...recentlyPaidInvoices.map((inv) => _buildPaidItem(
                            context: context,
                            invoice: inv,
                            currencyFormat: currencyFormat,
                          )),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncCard(BuildContext context, WidgetRef ref, SyncState state) {
    String title;
    String subtitle;
    IconData icon;
    Color color;

    switch (state) {
      case SyncState.synced:
        title = 'Cloud Synchronized';
        subtitle = 'All offline changes backed up to Firebase Cloud';
        icon = Icons.cloud_done_rounded;
        color = const Color(0xFF10B981);
        break;
      case SyncState.synchronizing:
        title = 'Synchronizing...';
        subtitle = 'Pushing local changes to cloud';
        icon = Icons.sync_rounded;
        color = const Color(0xFF0284C7);
        break;
      case SyncState.locallySaved:
        title = 'Saved Locally';
        subtitle = 'Stored in device Hive database • Ready to sync';
        icon = Icons.save_outlined;
        color = const Color(0xFF0284C7);
        break;
      case SyncState.syncPending:
        title = 'Sync Pending';
        subtitle = 'Waiting for network connection to upload';
        icon = Icons.cloud_queue_rounded;
        color = const Color(0xFFF59E0B);
        break;
      case SyncState.offline:
        title = 'Offline-First Mode';
        subtitle = 'Full read/write capability available offline';
        icon = Icons.cloud_off_rounded;
        color = const Color(0xFF64748B);
        break;
      case SyncState.syncFailed:
        title = 'Sync Interrupted';
        subtitle = 'Tap to retry synchronizing with cloud';
        icon = Icons.error_outline_rounded;
        color = const Color(0xFFEF4444);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          BouncingButton(
            scaleFactor: 0.90,
            onTap: () async {
              HapticFeedback.lightImpact();
              await syncAndRefreshEntireApp(ref);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Sync',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceAlertItem({
    required BuildContext context,
    required Invoice invoice,
    required NumberFormat currencyFormat,
    required bool isOverdue,
    required dynamic profile,
  }) {
    final days = invoice.dueDate.difference(DateTime.now()).inDays.abs();
    final timingText = isOverdue
        ? 'Overdue by $days ${days == 1 ? "day" : "days"}'
        : 'Due in $days ${days == 1 ? "day" : "days"}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isOverdue ? const Color(0xFFFECACA) : const Color(0xFFFED7AA)),
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
              color: isOverdue ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOverdue ? Icons.warning_amber_rounded : Icons.schedule_rounded,
              color: isOverdue ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${invoice.client.name} • ${currencyFormat.format(invoice.total)}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'INV-#${invoice.invoiceNumber} • $timingText',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isOverdue ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              BouncingButton(
                scaleFactor: 0.90,
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/preview', extra: invoice);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              BouncingButton(
                scaleFactor: 0.90,
                onTap: () {
                  ShareInvoiceBottomSheet.show(
                    context,
                    invoice: invoice,
                    profile: profile,
                    templateId: profile.invoiceTemplate.isNotEmpty ? profile.invoiceTemplate : 'modern',
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECE8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.share_outlined, size: 14, color: Color(0xFFFF5722)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaidItem({
    required BuildContext context,
    required Invoice invoice,
    required NumberFormat currencyFormat,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${invoice.client.name} • ${currencyFormat.format(invoice.total)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'INV-#${invoice.invoiceNumber} paid in full 🎉',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          BouncingButton(
            scaleFactor: 0.90,
            onTap: () {
              Navigator.of(context).pop();
              context.push('/preview', extra: invoice);
            },
            child: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
