import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../widgets/draw_signature_sheet.dart';
import '../../data/models/invoice.dart';
import '../providers/profile_provider.dart';
import '../providers/template_config_provider.dart';
import '../viewmodels/invoice_viewmodel.dart';
import '../../services/currency_tax_service.dart';
import '../../services/pdf_service.dart';
import '../widgets/share_invoice_bottom_sheet.dart';
import '../widgets/payment_qr_sheet.dart';
import '../widgets/bouncing_button.dart';
import '../widgets/animated_currency_text.dart';
import '../widgets/celebration_sparkle.dart';
import '../../services/interactive_invoice_service.dart';
import '../widgets/milestone_config_sheet.dart';
import '../widgets/payment_proof_sheet.dart';
import '../widgets/slide_to_confirm.dart';

class InvoicePreviewScreen extends ConsumerStatefulWidget {
  final Invoice invoice;

  const InvoicePreviewScreen({super.key, required this.invoice});

  @override
  ConsumerState<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends ConsumerState<InvoicePreviewScreen> {
  int _activeItemIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveInvoices = ref.watch(invoiceProvider);
    final currentInvoice = liveInvoices.firstWhere(
      (inv) => inv.id == widget.invoice.id,
      orElse: () => widget.invoice,
    );

    final profile = ref.watch(profileProvider);
    final templateConfig = ref.watch(templateConfigProvider);
    final activeTemplateId = templateConfig.templateId;

    final currencyFormat = CurrencyTaxService.getCurrencyFormatter(
      currencyCode: profile.currency.isNotEmpty ? profile.currency : 'USD',
      decimalDigits: 2,
    );

    final subtotal = currentInvoice.subtotal;
    final taxAmount = currentInvoice.taxAmount;
    final discountAmount = currentInvoice.discount;
    final grandTotal = currentInvoice.total;

    final senderName = profile.businessName.isNotEmpty ? profile.businessName : 'My Business';
    final senderAddress = profile.address.isNotEmpty ? profile.address : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top Header Bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BouncingButton(
                    scaleFactor: 0.90,
                    onTap: () => context.canPop() ? context.pop() : context.go('/dashboard'),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
                    ),
                  ),
                  const Text(
                    'Invoice Details',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  BouncingButton(
                    scaleFactor: 0.90,
                    onTap: () {
                      PaymentQrSheet.show(
                        context,
                        profile: profile,
                        invoice: currentInvoice,
                      );
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                      ),
                      child: const Icon(Icons.qr_code_2_rounded, size: 20, color: Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. Invoice ID ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            currentInvoice.invoiceNumber.startsWith('INV-')
                                ? currentInvoice.invoiceNumber
                                : (currentInvoice.invoiceNumber.startsWith('#')
                                    ? 'INV-${currentInvoice.invoiceNumber}'
                                    : 'INV-#${currentInvoice.invoiceNumber}'),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.6,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (currentInvoice.isPaid)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                                SizedBox(width: 4),
                                Text(
                                  'PAID',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF047857),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // ── Issued on & Due on Row ──
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Issued on:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd MMM yyyy').format(currentInvoice.issueDate),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Due on:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd MMM yyyy').format(currentInvoice.dueDate),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Bill from & Bill to Row (From Mockup) ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bill from
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Bill from', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFF0F172A),
                                child: Text(
                                  senderName.isNotEmpty ? senderName[0].toUpperCase() : 'J',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                senderName,
                                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                senderAddress,
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Bill to
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Bill to', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFF0F172A),
                                child: Text(
                                  currentInvoice.client.name.isNotEmpty ? currentInvoice.client.name[0].toUpperCase() : 'A',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currentInvoice.client.name,
                                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentInvoice.client.address.isNotEmpty ? currentInvoice.client.address : currentInvoice.client.email,
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),

                    // ── "Invoice details" Section Title & 3-Dot Indicator ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Invoice details',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                        ),
                        if (currentInvoice.items.length > 1)
                          Row(
                            children: List.generate(currentInvoice.items.length, (index) {
                              final isCurrent = _activeItemIndex == index;
                              return Container(
                                margin: const EdgeInsets.only(left: 4),
                                width: isCurrent ? 8 : 6,
                                height: isCurrent ? 8 : 6,
                                decoration: BoxDecoration(
                                  color: isCurrent ? const Color(0xFF0D3B3E) : const Color(0xFFCBD5E1),
                                  shape: BoxShape.circle,
                                ),
                              );
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ── Line Items Horizontal Swipeable Carousel (From Mockup) ──
                    SizedBox(
                      height: 198,
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: currentInvoice.items.length,
                        onPageChanged: (idx) => setState(() => _activeItemIndex = idx),
                        itemBuilder: (ctx, index) {
                          final item = currentInvoice.items[index];
                          final itemTotal = item.quantity * item.price;

                          return Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Description', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text(
                                  item.name,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 14),

                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Quantity', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 2),
                                          Text(
                                            item.quantity.toString(),
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Unit per-price', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 2),
                                          Text(
                                            currencyFormat.format(item.price),
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total price', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                                    Text(
                                      currencyFormat.format(itemTotal),
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── Calculation Breakdown (Subtotal, Tax, Discount, Grand Total) ──
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _buildAnimatedSummaryLine('Subtotal', subtotal, currencyFormat),
                          const SizedBox(height: 8),
                          _buildAnimatedSummaryLine('Tax (${currentInvoice.taxPercentage.toInt()}%)', taxAmount, currencyFormat),
                          if (discountAmount > 0) ...[
                            const SizedBox(height: 8),
                            _buildAnimatedSummaryLine('Discount', discountAmount, currencyFormat, prefix: '-'),
                          ],
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Grand total',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5, color: Color(0xFF0F172A)),
                              ),
                              AnimatedCurrencyText(
                                value: grandTotal,
                                formatter: currencyFormat,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Authorized Signatory (Applied from Profile) ──
                    if (profile.signatureUrl != null && profile.signatureUrl!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.verified_rounded, size: 18, color: Color(0xFF10B981)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Authorized Signatory',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Profile Signature',
                                        style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () async {
                                        await DrawSignatureBottomSheet.show(context);
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF5722).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Change',
                                          style: TextStyle(color: Color(0xFFFF5722), fontSize: 11, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              height: 48,
                              alignment: Alignment.centerLeft,
                              child: _buildSignatureImage(context, profile.signatureUrl!),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Signed by $senderName • Applied automatically from Profile',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF64748B).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.draw_outlined, size: 16, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Authorized Signature',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                                  ),
                                  Text(
                                    'Configure once in Profile to apply across all invoices',
                                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                await DrawSignatureBottomSheet.show(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF5722),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Sign Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),

                    // ── Interactive Web Link & Read Status Card ──
                    const SizedBox(height: 16),
                    _buildInteractiveLinkCard(context, currentInvoice),

                    // ── Payment Proof Banner (if submitted) ──
                    if (currentInvoice.hasPaymentProof) ...[
                      const SizedBox(height: 12),
                      _buildPaymentProofBanner(context, currentInvoice),
                    ],

                    const SizedBox(height: 12),

                    // ── Payment Milestones & Deposit Tranches ──
                    _buildMilestonesSection(context, currentInvoice, profile, currencyFormat),

                    const SizedBox(height: 22),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Sticky Bottom Bar: Slide to Paid + (Download invoice + Share invoice) ──
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                (MediaQuery.paddingOf(context).bottom > 0
                    ? MediaQuery.paddingOf(context).bottom + 8
                    : 16),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Slide to mark as Paid (or Paid Badge) above Download/Share ──
                  if (!currentInvoice.isPaid) ...[
                    SlideToConfirm(
                      label: 'Slide to mark as Paid',
                      completedLabel: 'Paid in Full 🎉',
                      progressColor: const Color(0xFF10B981),
                      icon: Icons.check_circle_rounded,
                      onConfirmed: () async {
                        await ref.read(invoiceProvider.notifier).togglePaymentStatus(currentInvoice.id);
                        if (context.mounted) {
                          CelebrationSparkle.show(
                            context,
                            message: 'Invoice #${currentInvoice.invoiceNumber} Paid! 🎉',
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Paid in Full 🎉',
                            style: TextStyle(
                              color: Color(0xFF047857),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Download invoice & Share invoice Row ──
                  Row(
                    children: [
                      // Download invoice button
                      Expanded(
                        child: BouncingButton(
                          onTap: () => PdfService.printInvoice(
                            currentInvoice,
                            profile,
                            templateId: activeTemplateId,
                          ),
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Download invoice',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Share invoice Orange button
                      Expanded(
                        child: BouncingButton(
                          onTap: () => ShareInvoiceBottomSheet.show(
                            context,
                            invoice: currentInvoice,
                            profile: profile,
                            templateId: activeTemplateId,
                          ),
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5722),
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF5722).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Share invoice',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildAnimatedSummaryLine(String title, double amount, NumberFormat format, {String? prefix}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        AnimatedCurrencyText(
          value: amount,
          formatter: format,
          prefix: prefix,
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildInteractiveLinkCard(BuildContext context, Invoice invoice) {
    final hasViewed = invoice.clientViewedAt != null;
    final viewCount = invoice.clientViewCount;
    final formattedTime = hasViewed
        ? DateFormat('dd MMM, h:mm a').format(invoice.clientViewedAt!)
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.link_rounded, size: 16, color: Color(0xFF0284C7)),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Live Web Invoice',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              // Read Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasViewed
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : const Color(0xFF64748B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasViewed ? Icons.remove_red_eye_rounded : Icons.visibility_off_outlined,
                      size: 13,
                      color: hasViewed ? const Color(0xFF10B981) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasViewed ? 'Viewed ($viewCount)' : 'Unopened',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: hasViewed ? const Color(0xFF10B981) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasViewed
                ? 'Client opened invoice on $formattedTime'
                : 'Send this lightweight link to track when the client views the bill.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => InteractiveInvoiceService.copyLinkToClipboard(context, invoice.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: const Text('Copy Link', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/inv/${invoice.id}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: const Text('Client Portal', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentProofBanner(BuildContext context, Invoice invoice) {
    final isVerified = invoice.paymentProofStatus == 'verified';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isVerified
            ? const Color(0xFF10B981).withValues(alpha: 0.08)
            : const Color(0xFFF59E0B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVerified
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : const Color(0xFFF59E0B).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
            color: isVerified ? const Color(0xFF10B981) : const Color(0xFFD97706),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVerified ? 'Payment Proof Verified' : 'Client Uploaded Proof of Payment',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: isVerified ? const Color(0xFF10B981) : const Color(0xFFD97706),
                  ),
                ),
                Text(
                  'UTR: ${invoice.paymentProofRef ?? "Submitted"}',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          if (!isVerified)
            ElevatedButton(
              onPressed: () {
                ReviewProofDialog.show(
                  context,
                  invoice: invoice,
                  onVerifyPaid: () {
                    ref.read(invoiceProvider.notifier).verifyPaymentProof(invoice.id);
                    CelebrationSparkle.show(context);
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('Review', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildMilestonesSection(
    BuildContext context,
    Invoice invoice,
    dynamic profile,
    NumberFormat currencyFormat,
  ) {
    if (invoice.hasMilestones) {
      final paidCount = invoice.paidMilestones.length;
      final totalCount = invoice.milestones.length;

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.splitscreen_rounded, size: 15, color: Color(0xFFFF5722)),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Payment Milestones',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    MilestoneConfigSheet.show(
                      context,
                      totalAmount: invoice.total,
                      currencyCode: profile.currency,
                      initialMilestones: invoice.milestones,
                      onSave: (newMilestones) {
                        ref.read(invoiceProvider.notifier).updateMilestones(invoice.id, newMilestones);
                      },
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Edit Tranches', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFFF5722))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$paidCount of $totalCount Milestones Paid (${currencyFormat.format(invoice.milestonesTotalPaid)} / ${currencyFormat.format(invoice.total)})',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            ...invoice.milestones.map((m) {
              final isPaid = m.isPaid;
              final isActive = m.isActive;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isPaid
                      ? const Color(0xFF10B981).withValues(alpha: 0.06)
                      : (isActive ? const Color(0xFFFF5722).withValues(alpha: 0.05) : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPaid
                        ? const Color(0xFF10B981).withValues(alpha: 0.3)
                        : (isActive ? const Color(0xFFFF5722).withValues(alpha: 0.4) : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPaid ? Icons.check_circle_rounded : (isActive ? Icons.play_arrow_rounded : Icons.lock_outline_rounded),
                      size: 16,
                      color: isPaid ? const Color(0xFF10B981) : (isActive ? const Color(0xFFFF5722) : const Color(0xFF94A3B8)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        m.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isPaid ? const Color(0xFF10B981) : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      currencyFormat.format(m.amount),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isPaid ? const Color(0xFF10B981) : const Color(0xFF0F172A),
                      ),
                    ),
                    if (isActive && !invoice.isPaid) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          ref.read(invoiceProvider.notifier).markMilestonePaid(invoice.id, m.id);
                          CelebrationSparkle.show(context, message: '${m.title} Paid! 🎉');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Mark Paid', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      );
    }

    // No milestones yet - show quick action
    return GestureDetector(
      onTap: () {
        MilestoneConfigSheet.show(
          context,
          totalAmount: invoice.total,
          currencyCode: profile.currency,
          initialMilestones: const [],
          onSave: (newMilestones) {
            ref.read(invoiceProvider.notifier).updateMilestones(invoice.id, newMilestones);
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5722).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.splitscreen_rounded, size: 16, color: Color(0xFFFF5722)),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Split into Payment Milestones',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                  ),
                  Text(
                    'E.g. 40% deposit, 30% mid-review, 30% handover',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureImage(BuildContext context, String signaturePath) {
    if (kIsWeb || signaturePath.startsWith('http://') || signaturePath.startsWith('https://')) {
      return Image.network(
        signaturePath,
        fit: BoxFit.contain,
        errorBuilder: (ctx, err, stack) => _buildSignatureMissingFallback(context),
      );
    }

    if (signaturePath.startsWith('data:image')) {
      try {
        final commaIdx = signaturePath.indexOf(',');
        final base64Str = commaIdx != -1 ? signaturePath.substring(commaIdx + 1) : signaturePath;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (ctx, err, stack) => _buildSignatureMissingFallback(context),
        );
      } catch (_) {
        return _buildSignatureMissingFallback(context);
      }
    }

    final file = File(signaturePath);
    if (!file.existsSync()) {
      return _buildSignatureMissingFallback(context);
    }

    return Image.file(
      file,
      fit: BoxFit.contain,
      errorBuilder: (ctx, err, stack) => _buildSignatureMissingFallback(context),
    );
  }

  Widget _buildSignatureMissingFallback(BuildContext context) {
    return InkWell(
      onTap: () async {
        await DrawSignatureBottomSheet.show(context);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.draw_rounded, size: 16, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            const Text(
              'Signature file missing • Tap to re-draw',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Re-draw', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

