import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/invoice.dart';
import '../providers/profile_provider.dart';
import '../viewmodels/invoice_viewmodel.dart';
import '../../services/currency_tax_service.dart';
import '../../services/pdf_service.dart';
import 'package:printing/printing.dart';
import '../widgets/share_invoice_bottom_sheet.dart';
import '../widgets/payment_qr_sheet.dart';
import '../widgets/draw_signature_sheet.dart';
import '../widgets/status_badge.dart';
import '../widgets/pdf_shimmer_skeleton.dart';
import '../widgets/bouncing_button.dart';
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
  int _selectedViewTab = 0; // 0: Summary, 1: PDF Document
  String? _selectedTemplateId;
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

  void _handleSetDefaultTemplate(String templateId) {
    HapticFeedback.mediumImpact();
    final profile = ref.read(profileProvider);
    final updatedProfile = profile.copyWith(invoiceTemplate: templateId);
    ref.read(profileProvider.notifier).updateProfile(updatedProfile);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
            const SizedBox(width: 8),
            Text('Saved as default template!'),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final liveInvoices = ref.watch(invoiceProvider);
    final currentInvoice = liveInvoices.firstWhere(
      (inv) => inv.id == widget.invoice.id,
      orElse: () => widget.invoice,
    );

    final profile = ref.watch(profileProvider);
    final activeTemplateId = _selectedTemplateId ?? (profile.invoiceTemplate.isNotEmpty ? profile.invoiceTemplate : 'modern');

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
        child: Column(
          children: [
            // ── Top Header Bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
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
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _handleDuplicateInvoice(currentInvoice),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                          ),
                          child: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF0F172A)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          final applied = await DrawSignatureBottomSheet.show(context);
                          if (applied == true && mounted) {
                            setState(() {});
                          }
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (profile.signatureUrl != null && profile.signatureUrl!.isNotEmpty)
                                ? const Color(0xFFFFECE8)
                                : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: (profile.signatureUrl != null && profile.signatureUrl!.isNotEmpty)
                                  ? const Color(0xFFFF5722)
                                  : const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                          ),
                          child: Icon(
                            Icons.draw_rounded,
                            size: 19,
                            color: (profile.signatureUrl != null && profile.signatureUrl!.isNotEmpty)
                                ? const Color(0xFFFF5722)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
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
                ],
              ),
            ),

            // ── Segmented View Switcher (Summary vs PDF Preview) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedViewTab = 0);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: _selectedViewTab == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(17),
                            boxShadow: _selectedViewTab == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.dashboard_outlined,
                                  size: 15,
                                  color: _selectedViewTab == 0 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Summary',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: _selectedViewTab == 0 ? FontWeight.w800 : FontWeight.w600,
                                    color: _selectedViewTab == 0 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedViewTab = 1);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: _selectedViewTab == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(17),
                            boxShadow: _selectedViewTab == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.picture_as_pdf_outlined,
                                  size: 15,
                                  color: _selectedViewTab == 1 ? const Color(0xFFFF5722) : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'PDF Preview',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: _selectedViewTab == 1 ? FontWeight.w800 : FontWeight.w600,
                                    color: _selectedViewTab == 1 ? const Color(0xFFFF5722) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_selectedViewTab == 1)
              Expanded(
                child: Column(
                  children: [
                    // Template Selector Bar
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            ...PdfService.availableTemplates.map((template) {
                              final isSelected = activeTemplateId == template.id;
                              final color = Color(int.parse(template.primaryColorHex.replaceFirst('#', '0xFF')));

                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedTemplateId = template.id);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? color : const Color(0xFFE2E8F0),
                                      width: isSelected ? 1.6 : 1.0,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: color.withValues(alpha: 0.15),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(template.icon, style: const TextStyle(fontSize: 13)),
                                      const SizedBox(width: 6),
                                      Text(
                                        template.name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                          color: isSelected ? color : const Color(0xFF64748B),
                                        ),
                                      ),
                                      if (profile.invoiceTemplate == template.id) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          width: 5,
                                          height: 5,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }),
                            if (profile.invoiceTemplate != activeTemplateId)
                              GestureDetector(
                                onTap: () => _handleSetDefaultTemplate(activeTemplateId),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Set Default',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            GestureDetector(
                              onTap: () async {
                                final result = await context.push('/templates');
                                if (result is String) {
                                  setState(() => _selectedTemplateId = result);
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.view_carousel_rounded, size: 14, color: Colors.white),
                                    SizedBox(width: 5),
                                    Text(
                                      'Studio',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
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

                    // PDF Preview Viewer with Key
                    Expanded(
                      child: PdfPreview(
                        key: ValueKey('pdf_${activeTemplateId}_${profile.signatureUrl ?? ""}'),
                        build: (format) => PdfService.generateInvoicePdf(
                          currentInvoice,
                          profile,
                          templateId: activeTemplateId,
                        ),
                        allowPrinting: false,
                        allowSharing: false,
                        canChangeOrientation: false,
                        canChangePageFormat: false,
                        canDebug: false,
                        scrollViewDecoration: const BoxDecoration(color: Colors.transparent),
                        pdfFileName: 'Invoice-${currentInvoice.invoiceNumber}.pdf',
                        loadingWidget: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: SingleChildScrollView(
                            physics: NeverScrollableScrollPhysics(),
                            child: PdfShimmerSkeleton(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Invoice ID & Status Pill ──
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
                          const SizedBox(width: 8),
                          StatusBadge(
                            status: currentInvoice.status,
                            dueDate: currentInvoice.dueDate,
                            fontSize: 13,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            onTap: () {
                              final willBePaid = !currentInvoice.isPaid;
                              ref.read(invoiceProvider.notifier).togglePaymentStatus(currentInvoice.id);
                              if (willBePaid) {
                                CelebrationSparkle.show(
                                  context,
                                  message: 'Invoice #${currentInvoice.invoiceNumber} Paid! 🎉',
                                );
                              } else {
                                HapticFeedback.mediumImpact();
                              }
                            },
                          ),
                        ],
                      ),

                      if (!currentInvoice.isPaid) ...[
                        const SizedBox(height: 14),
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
                      ],

                      const SizedBox(height: 14),

                      // ── Interactive Web Link & Read Status Card ──
                      _buildInteractiveLinkCard(context, currentInvoice),

                      // ── Payment Proof Banner (if submitted) ──
                      if (currentInvoice.hasPaymentProof) ...[
                        const SizedBox(height: 12),
                        _buildPaymentProofBanner(context, currentInvoice),
                      ],

                      const SizedBox(height: 12),

                      // ── Payment Milestones & Deposit Tranches ──
                      _buildMilestonesSection(context, currentInvoice, profile, currencyFormat),

                      const SizedBox(height: 16),

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
                          _buildSummaryLine('Subtotal', currencyFormat.format(subtotal)),
                          const SizedBox(height: 8),
                          _buildSummaryLine('Tax (${currentInvoice.taxPercentage.toInt()}%)', currencyFormat.format(taxAmount)),
                          if (discountAmount > 0) ...[
                            const SizedBox(height: 8),
                            _buildSummaryLine('Discount', '-${currencyFormat.format(discountAmount)}'),
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
                              Text(
                                currencyFormat.format(grandTotal),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Signatory & Digital Signature Card ──
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
                                  Icon(Icons.draw_rounded, size: 18, color: Color(0xFFFF5722)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Authorized Signatory',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFFF5722),
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () async {
                                  final res = await DrawSignatureBottomSheet.show(context);
                                  if (res == true && mounted) setState(() {});
                                },
                                child: Text(
                                  (profile.signatureUrl != null && profile.signatureUrl!.isNotEmpty)
                                      ? 'Redraw'
                                      : 'Draw Signature',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (profile.signatureUrl != null && profile.signatureUrl!.isNotEmpty) ...[
                            Container(
                              height: 50,
                              alignment: Alignment.centerLeft,
                              child: Image.file(File(profile.signatureUrl!), fit: BoxFit.contain),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Signature attached • Appears on PDF bill',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                            ),
                          ] else ...[
                            InkWell(
                              onTap: () async {
                                final res = await DrawSignatureBottomSheet.show(context);
                                if (res == true && mounted) setState(() {});
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.draw_outlined, size: 18, color: Color(0xFFFF5722)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Tap here to draw signature on this bill',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFFF5722)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // ── Sticky Bottom Buttons Row (Download invoice + Share invoice) ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
              child: Row(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryLine(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w700)),
      ],
    );
  }

  Future<void> _handleDuplicateInvoice(Invoice invoice) async {
    HapticFeedback.lightImpact();
    final shouldDuplicate = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.content_copy_rounded, color: Color(0xFFFF5722), size: 22),
            SizedBox(width: 10),
            Text('Duplicate Invoice', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: Text(
          'Create a duplicate copy of INV-#${invoice.invoiceNumber} for "${invoice.client.name}" with a fresh invoice number and today\'s date?',
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5722),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              elevation: 0,
            ),
            child: const Text('Duplicate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldDuplicate == true && mounted) {
      HapticFeedback.mediumImpact();
      final duplicatedInvoice = await ref.read(invoiceProvider.notifier).duplicateAsNewInvoice(invoice);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Duplicated as INV-#${duplicatedInvoice.invoiceNumber}'),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pushReplacement('/preview', extra: duplicatedInvoice);
      }
    }
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
}

