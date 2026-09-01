import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/invoice.dart';
import '../providers/profile_provider.dart';
import '../viewmodels/invoice_viewmodel.dart';
import '../../services/currency_tax_service.dart';
import '../../services/pdf_service.dart';
import '../widgets/share_invoice_bottom_sheet.dart';
import '../widgets/payment_qr_sheet.dart';

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
    final isPaid = currentInvoice.status.toLowerCase() == 'paid';

    final currencyFormat = CurrencyTaxService.getCurrencyFormatter(
      currencyCode: profile.currency.isNotEmpty ? profile.currency : 'USD',
      decimalDigits: 2,
    );

    final subtotal = currentInvoice.subtotal;
    final taxAmount = currentInvoice.taxAmount;
    final discountAmount = currentInvoice.discount;
    final grandTotal = currentInvoice.total;

    final senderName = profile.businessName.isNotEmpty ? profile.businessName : 'Jamil Suta';
    final senderAddress = profile.address.isNotEmpty ? profile.address : '553, Park Avenue, East Side New York';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header Bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
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
            ),

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
                        Text(
                          'INV-#${currentInvoice.invoiceNumber}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.6,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isPaid ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isPaid ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            isPaid ? 'Paid' : 'Unpaid',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: isPaid ? const Color(0xFF10B981) : const Color(0xFF64748B),
                            ),
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
                      height: 175,
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
                            padding: const EdgeInsets.all(18),
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
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => PdfService.printInvoice(currentInvoice, profile),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        ),
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

                  // Share invoice Lime button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => ShareInvoiceBottomSheet.show(context, invoice: currentInvoice, profile: profile),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9BD71B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Share invoice',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
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
}
