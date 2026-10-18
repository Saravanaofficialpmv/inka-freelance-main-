import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/theme_helper.dart';
import '../../data/models/invoice.dart';
import '../../data/models/payment_milestone.dart';
import '../providers/profile_provider.dart';
import '../viewmodels/invoice_viewmodel.dart';
import '../../services/currency_tax_service.dart';
import '../../services/interactive_invoice_service.dart';
import '../../services/pdf_service.dart';
import 'package:printing/printing.dart';
import '../widgets/payment_proof_sheet.dart';
import '../widgets/status_badge.dart';
import '../widgets/celebration_sparkle.dart';

class InteractiveWebInvoiceScreen extends ConsumerStatefulWidget {
  final String invoiceId;

  const InteractiveWebInvoiceScreen({
    super.key,
    required this.invoiceId,
  });

  @override
  ConsumerState<InteractiveWebInvoiceScreen> createState() => _InteractiveWebInvoiceScreenState();
}

class _InteractiveWebInvoiceScreenState extends ConsumerState<InteractiveWebInvoiceScreen> {
  bool _hasLoggedView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasLoggedView && mounted) {
        _hasLoggedView = true;
        ref.read(invoiceProvider.notifier).recordClientView(widget.invoiceId);
      }
    });
  }

  void _handleOpenProofSheet(Invoice invoice, [PaymentMilestone? milestone]) {
    PaymentProofSheet.show(
      context,
      invoice: invoice,
      milestone: milestone,
      onSubmit: (refNumber, note, imageBase64) {
        ref.read(invoiceProvider.notifier).submitPaymentProof(
              invoice.id,
              refNumber: refNumber,
              note: note,
              imageBase64: imageBase64,
              milestoneId: milestone?.id,
            );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Proof of payment submitted successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoices = ref.watch(invoiceProvider);
    final profile = ref.watch(profileProvider);

    Invoice? invoice;
    try {
      invoice = invoices.firstWhere(
        (inv) => inv.id == widget.invoiceId || inv.invoiceNumber == widget.invoiceId,
      );
    } catch (_) {
      invoice = null;
    }

    if (invoice == null) {
      return Scaffold(
        backgroundColor: context.scaffoldBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long_outlined, color: Color(0xFFEF4444), size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  'Invoice Not Found',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'The invoice reference "${widget.invoiceId}" could not be located.',
                  style: TextStyle(fontSize: 13, color: context.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/dashboard');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Return to Home', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currencyFormat = CurrencyTaxService.getCurrencyFormatter(
      currencyCode: profile.currency.isNotEmpty ? profile.currency : 'USD',
      decimalDigits: 2,
    );
    final senderName = profile.businessName.isNotEmpty ? profile.businessName : 'Inka Freelancer';
    final isWide = MediaQuery.sizeOf(context).width >= 780;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              children: [
                // ── Top Navigation Bar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (Navigator.of(context).canPop())
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    color: context.circleBtnBg,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: context.cardBorder),
                                  ),
                                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: context.textPrimary),
                                ),
                              ),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_rounded, size: 13, color: Color(0xFF10B981)),
                                    SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'inka.link Verified',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF10B981),
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
                      const SizedBox(width: 6),
                      Row(
                        children: [
                          // Copy link button
                          GestureDetector(
                            onTap: () => InteractiveInvoiceService.copyLinkToClipboard(context, invoice!.id),
                            child: Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: context.circleBtnBg,
                                shape: BoxShape.circle,
                                border: Border.all(color: context.cardBorder),
                              ),
                              child: Icon(Icons.link_rounded, size: 18, color: context.textPrimary),
                            ),
                          ),
                          // PDF print/download action
                          GestureDetector(
                            onTap: () async {
                              final pdfBytes = await PdfService.generateInvoicePdf(invoice!, profile);
                              await Printing.layoutPdf(
                                onLayout: (_) => pdfBytes,
                                name: 'Invoice-${invoice!.invoiceNumber}.pdf',
                              );
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: context.circleBtnBg,
                                shape: BoxShape.circle,
                                border: Border.all(color: context.cardBorder),
                              ),
                              child: Icon(Icons.download_rounded, size: 18, color: context.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Scrollable Body ──
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(isWide ? 28 : 16, 4, isWide ? 28 : 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 1. Read Receipt Status Banner ──
                        _buildReadReceiptBanner(invoice),
                        const SizedBox(height: 12),

                        // ── 2. Primary Invoice Summary Header Card ──
                        _buildHeaderCard(context, invoice, senderName, currencyFormat),
                        const SizedBox(height: 16),

                        // ── 3. Payment Milestones & Deposit Tranches ──
                        if (invoice.hasMilestones) ...[
                          _buildMilestonesTimeline(context, invoice, currencyFormat),
                          const SizedBox(height: 16),
                        ],

                        // ── 4. Proof of Payment Status / Upload Card ──
                        _buildProofOfPaymentCard(context, invoice),
                        const SizedBox(height: 16),

                        // ── 5. Payment Methods (UPI & Bank Transfer) ──
                        _buildPaymentChannelsCard(context, profile, invoice, currencyFormat),
                        const SizedBox(height: 16),

                        // ── 6. Itemized Services Breakdown ──
                        _buildItemsBreakdownCard(context, invoice, currencyFormat),
                        const SizedBox(height: 24),

                        // Footer branding
                        Center(
                          child: Text(
                            'Powered by Inka • Fast, Secure Invoicing for Freelancers',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: context.textMuted,
                              fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }

  Widget _buildReadReceiptBanner(Invoice invoice) {
    final viewedAt = invoice.clientViewedAt ?? DateTime.now();
    final count = invoice.clientViewCount > 0 ? invoice.clientViewCount : 1;
    final formattedTime = DateFormat('MMM dd, yyyy • h:mm a').format(viewedAt);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0284C7).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.remove_red_eye_rounded, size: 15, color: Color(0xFF0284C7)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Live Read Receipt Active',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count ${count == 1 ? "view" : "views"}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Client opened: $formattedTime',
                  style: TextStyle(fontSize: 11, color: context.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    Invoice invoice,
    String senderName,
    NumberFormat currencyFormat,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      senderName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Invoice #${invoice.invoiceNumber}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: context.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                status: invoice.status,
                dueDate: invoice.dueDate,
                fontSize: 12,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: context.cardBorder),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BILLED TO',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: context.textSecondary, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      invoice.client.name,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.textPrimary),
                    ),
                    if (invoice.client.email.isNotEmpty)
                      Text(invoice.client.email, style: TextStyle(fontSize: 12, color: context.textSecondary)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TOTAL PAYABLE',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: context.textSecondary, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(invoice.total),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Due ${DateFormat('dd MMM yyyy').format(invoice.dueDate)}',
                      style: TextStyle(fontSize: 11.5, color: context.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesTimeline(
    BuildContext context,
    Invoice invoice,
    NumberFormat currencyFormat,
  ) {
    final paidCount = invoice.paidMilestones.length;
    final totalCount = invoice.milestones.length;
    final progress = totalCount > 0 ? (paidCount / totalCount).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.splitscreen_rounded, size: 16, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Payment Tranches & Milestones',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$paidCount of $totalCount Settled',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: context.surfaceHighlight,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),

          // Milestone Cards
          ...invoice.milestones.map((m) {
            final isPaid = m.isPaid;
            final isActive = m.isActive;

            Color borderColor;
            Color bgColor;
            if (isPaid) {
              borderColor = const Color(0xFF10B981).withValues(alpha: 0.4);
              bgColor = const Color(0xFF10B981).withValues(alpha: 0.06);
            } else if (isActive) {
              borderColor = AppColors.primary;
              bgColor = AppColors.primary.withValues(alpha: 0.06);
            } else {
              borderColor = context.cardBorder;
              bgColor = context.surfaceHighlight;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor, width: isActive ? 1.6 : 1.0),
              ),
              child: Row(
                children: [
                  // Indicator
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isPaid
                          ? const Color(0xFF10B981)
                          : (isActive ? AppColors.primary : context.cardBorder),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isPaid
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                          : (isActive
                              ? const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18)
                              : const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 15)),
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                m.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: context.textPrimary,
                                ),
                              ),
                            ),
                            if (isPaid)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'PAID',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              )
                            else if (isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'DUE NOW',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${m.percentage.toStringAsFixed(0)}% • ${currencyFormat.format(m.amount)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isPaid ? const Color(0xFF10B981) : (isActive ? AppColors.primary : context.textSecondary),
                                ),
                              ),
                            ),
                            if (isActive && !invoice.isPaid) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _handleOpenProofSheet(invoice, m),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Pay Tranche',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProofOfPaymentCard(BuildContext context, Invoice invoice) {
    if (invoice.isPaid) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Invoice Fully Settled',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                  ),
                  Text(
                    'Official receipt voucher generated and verified.',
                    style: TextStyle(fontSize: 12, color: context.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (invoice.hasPaymentProof) {
      final isVerified = invoice.paymentProofStatus == 'verified';
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isVerified
              ? const Color(0xFF10B981).withValues(alpha: 0.08)
              : const Color(0xFFF59E0B).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isVerified
                ? const Color(0xFF10B981).withValues(alpha: 0.3)
                : const Color(0xFFF59E0B).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isVerified ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                  color: isVerified ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isVerified ? 'Payment Proof Verified' : 'Proof of Payment Submitted',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: isVerified ? const Color(0xFF10B981) : const Color(0xFFD97706),
                    ),
                  ),
                ),
                if (!isVerified)
                  ElevatedButton(
                    onPressed: () {
                      ref.read(invoiceProvider.notifier).verifyPaymentProof(invoice.id);
                      CelebrationSparkle.show(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('Verify & Settle', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Reference / UTR: ${invoice.paymentProofRef ?? "Recorded"}',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.textPrimary),
            ),
            if (invoice.paymentProofNote != null && invoice.paymentProofNote!.isNotEmpty)
              Text(
                'Note: "${invoice.paymentProofNote}"',
                style: TextStyle(fontSize: 12, color: context.textSecondary),
              ),
          ],
        ),
      );
    }

    // Default "I've Paid" CTA button
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_outlined, size: 18, color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Already Transferred Funds?",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.textPrimary),
                    ),
                    Text(
                      "Submit your transaction UTR or screenshot to confirm instantly.",
                      style: TextStyle(fontSize: 12, color: context.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _handleOpenProofSheet(invoice),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: const Text(
                "I've Paid • Upload Proof",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentChannelsCard(
    BuildContext context,
    dynamic profile,
    Invoice invoice,
    NumberFormat currencyFormat,
  ) {
    final hasUpi = profile.upiId != null && profile.upiId.isNotEmpty;
    final hasBank = profile.accountNo != null && profile.accountNo.isNotEmpty;

    if (!hasUpi && !hasBank) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.payment_rounded, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                'Payment Details',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // UPI ID Option
          if (hasUpi) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.surfaceHighlight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.qr_code_2_rounded, size: 18, color: Color(0xFF0284C7)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('UPI ID', style: TextStyle(fontSize: 11, color: context.textSecondary, fontWeight: FontWeight.bold)),
                        Text(
                          profile.upiId,
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: context.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    color: AppColors.primary,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: profile.upiId));
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('UPI ID copied to clipboard!'), duration: Duration(seconds: 1)),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Bank Details Option
          if (hasBank) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.surfaceHighlight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.cardBorder),
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
                    child: const Icon(Icons.account_balance_rounded, size: 18, color: Color(0xFF10B981)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DIRECT BANK TRANSFER', style: TextStyle(fontSize: 10.5, color: context.textSecondary, fontWeight: FontWeight.bold)),
                        Text(
                          '${profile.bankName ?? "Bank"} • ${profile.accountNo}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.textPrimary),
                        ),
                        if (profile.ifscCode != null && profile.ifscCode.isNotEmpty)
                          Text('IFSC: ${profile.ifscCode}', style: TextStyle(fontSize: 11.5, color: context.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    color: AppColors.primary,
                    onPressed: () {
                      final bankInfo = 'Bank: ${profile.bankName}\nA/C: ${profile.accountNo}\nIFSC: ${profile.ifscCode}';
                      Clipboard.setData(ClipboardData(text: bankInfo));
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bank details copied to clipboard!'), duration: Duration(seconds: 1)),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsBreakdownCard(
    BuildContext context,
    Invoice invoice,
    NumberFormat currencyFormat,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Services & Products Breakdown',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: context.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${invoice.items.length} ${invoice.items.length == 1 ? "Item" : "Items"}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ...invoice.items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: context.textPrimary),
                        ),
                        Text(
                          '${item.quantity} × ${currencyFormat.format(item.price)}',
                          style: TextStyle(fontSize: 12, color: context.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currencyFormat.format(item.total),
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: context.textPrimary),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 10),
          Divider(height: 1, color: context.cardBorder),
          const SizedBox(height: 10),

          // Subtotal
          _buildSummaryRow(context, 'Subtotal', currencyFormat.format(invoice.subtotal)),
          if (invoice.taxAmount > 0)
            _buildSummaryRow(context, 'Tax (${invoice.taxPercentage.toStringAsFixed(0)}%)', currencyFormat.format(invoice.taxAmount)),
          if (invoice.discount > 0)
            _buildSummaryRow(context, 'Discount', '-${currencyFormat.format(invoice.discount)}', isNegative: true),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('Grand Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: context.textPrimary)),
              ),
              const SizedBox(width: 8),
              Text(
                currencyFormat.format(invoice.total),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value, {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 12.5, color: context.textSecondary)),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isNegative ? const Color(0xFFEF4444) : context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
