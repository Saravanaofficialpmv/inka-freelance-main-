import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/models/payment_milestone.dart';

class InteractiveInvoiceService {
  /// Base domain for live interactive web invoices
  static const String baseDomain = 'https://inka.link';

  /// Generates the canonical web link for an invoice
  static String getInteractiveInvoiceUrl(String invoiceId) {
    return '$baseDomain/inv/$invoiceId';
  }

  /// Copies the interactive invoice link to the user's clipboard
  static void copyLinkToClipboard(BuildContext context, String invoiceId) {
    final link = getInteractiveInvoiceUrl(invoiceId);
    Clipboard.setData(ClipboardData(text: link));
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.link_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Live link copied: $link',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Generates a 50/50 milestone split
  static List<PaymentMilestone> generate50_50Split({
    required double totalAmount,
    DateTime? startDate,
    DateTime? finalDueDate,
  }) {
    final half = (totalAmount * 0.5);
    final now = startDate ?? DateTime.now();
    final end = finalDueDate ?? now.add(const Duration(days: 30));

    return [
      PaymentMilestone(
        id: 'ms_${now.millisecondsSinceEpoch}_1',
        title: '50% Upfront Deposit',
        percentage: 50.0,
        amount: half,
        dueDate: now.add(const Duration(days: 3)),
        status: 'active',
      ),
      PaymentMilestone(
        id: 'ms_${now.millisecondsSinceEpoch}_2',
        title: '50% Final Project Delivery',
        percentage: 50.0,
        amount: totalAmount - half,
        dueDate: end,
        status: 'pending',
      ),
    ];
  }

  /// Generates a 40/30/30 milestone split
  static List<PaymentMilestone> generate40_30_30Split({
    required double totalAmount,
    DateTime? startDate,
    DateTime? finalDueDate,
  }) {
    final m1 = (totalAmount * 0.40);
    final m2 = (totalAmount * 0.30);
    final m3 = (totalAmount - m1 - m2);
    final now = startDate ?? DateTime.now();
    final end = finalDueDate ?? now.add(const Duration(days: 30));
    final mid = now.add(Duration(days: ((end.difference(now).inDays) / 2).round().clamp(7, 60)));

    return [
      PaymentMilestone(
        id: 'ms_${now.millisecondsSinceEpoch}_1',
        title: '40% Upfront Deposit & Kickoff',
        percentage: 40.0,
        amount: m1,
        dueDate: now.add(const Duration(days: 3)),
        status: 'active',
      ),
      PaymentMilestone(
        id: 'ms_${now.millisecondsSinceEpoch}_2',
        title: '30% Mid-Project Review & Approval',
        percentage: 30.0,
        amount: m2,
        dueDate: mid,
        status: 'pending',
      ),
      PaymentMilestone(
        id: 'ms_${now.millisecondsSinceEpoch}_3',
        title: '30% Final Delivery & Handover',
        percentage: 30.0,
        amount: m3,
        dueDate: end,
        status: 'pending',
      ),
    ];
  }

  /// Generates a 30/40/30 milestone split
  static List<PaymentMilestone> generate30_40_30Split({
    required double totalAmount,
    DateTime? startDate,
    DateTime? finalDueDate,
  }) {
    final m1 = (totalAmount * 0.30);
    final m2 = (totalAmount * 0.40);
    final m3 = (totalAmount - m1 - m2);
    final now = startDate ?? DateTime.now();
    final end = finalDueDate ?? now.add(const Duration(days: 30));
    final mid = now.add(Duration(days: ((end.difference(now).inDays) / 2).round().clamp(7, 60)));

    return [
      PaymentMilestone(
        id: 'ms_${now.millisecondsSinceEpoch}_1',
        title: '30% Discovery & Scoping Deposit',
        percentage: 30.0,
        amount: m1,
        dueDate: now.add(const Duration(days: 3)),
        status: 'active',
      ),
      PaymentMilestone(
        id: 'ms_${now.millisecondsSinceEpoch}_2',
        title: '40% Functional Build & Demo',
        percentage: 40.0,
        amount: m2,
        dueDate: mid,
        status: 'pending',
      ),
      PaymentMilestone(
        id: 'ms_${now.millisecondsSinceEpoch}_3',
        title: '30% Deployment & Assets Handover',
        percentage: 30.0,
        amount: m3,
        dueDate: end,
        status: 'pending',
      ),
    ];
  }
}
