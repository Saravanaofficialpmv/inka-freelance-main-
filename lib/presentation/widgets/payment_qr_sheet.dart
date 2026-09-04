import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/colors.dart';
import '../../data/models/business_profile.dart';
import '../../data/models/invoice.dart';
import '../../services/currency_tax_service.dart';
import '../../services/payment_qr_service.dart';
import '../viewmodels/invoice_viewmodel.dart';
import 'celebration_sparkle.dart';

class PaymentQrSheet extends ConsumerStatefulWidget {
  final BusinessProfile profile;
  final Invoice? invoice;
  final double? customAmount;

  const PaymentQrSheet({
    super.key,
    required this.profile,
    this.invoice,
    this.customAmount,
  });

  static Future<void> show(
    BuildContext context, {
    required BusinessProfile profile,
    Invoice? invoice,
    double? customAmount,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaymentQrSheet(
        profile: profile,
        invoice: invoice,
        customAmount: customAmount,
      ),
    );
  }

  @override
  ConsumerState<PaymentQrSheet> createState() => _PaymentQrSheetState();
}

class _PaymentQrSheetState extends ConsumerState<PaymentQrSheet> with SingleTickerProviderStateMixin {
  UpiAppType _selectedApp = UpiAppType.generic;
  bool _isMarkingPaid = false;
  bool _isPaymentDone = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _isPaymentDone = widget.invoice?.status.toLowerCase() == 'paid';
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
    if (_isPaymentDone) {
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleMarkAsPaid() async {
    if (widget.invoice == null) return;
    setState(() => _isMarkingPaid = true);
    HapticFeedback.mediumImpact();

    await ref.read(invoiceProvider.notifier).togglePaymentStatus(widget.invoice!.id);

    if (mounted) {
      setState(() {
        _isMarkingPaid = false;
        _isPaymentDone = true;
      });
      _animController.forward(from: 0.0);
      CelebrationSparkle.show(
        context,
        message: 'Payment Recorded! 🎉',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final liveInvoices = ref.watch(invoiceProvider);
    final currentInvoice = widget.invoice != null
        ? liveInvoices.firstWhere(
            (inv) => inv.id == widget.invoice!.id,
            orElse: () => widget.invoice!,
          )
        : null;

    final isPaid = _isPaymentDone || (currentInvoice?.status.toLowerCase() == 'paid');

    final upiId = (widget.profile.upiId != null && widget.profile.upiId!.isNotEmpty)
        ? widget.profile.upiId!
        : '${widget.profile.email.split("@").first}@okaxis';

    final payeeName = widget.profile.businessName.isNotEmpty
        ? widget.profile.businessName
        : 'Inka Business';

    final double amount = currentInvoice?.total ?? widget.customAmount ?? 0.0;
    final invoiceNumber = currentInvoice?.invoiceNumber;

    final currencyFormatter = CurrencyTaxService.getCurrencyFormatter(
      currencyCode: widget.profile.currency.isNotEmpty ? widget.profile.currency : 'INR',
      decimalDigits: 2,
    );

    final upiString = PaymentQrService.buildUpiUrl(
      upiId: upiId,
      payeeName: payeeName,
      amount: amount > 0 ? amount : null,
      invoiceNumber: invoiceNumber,
      appType: _selectedApp,
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        left: 24,
        right: 24,
        top: 16,
      ),
      child: isPaid
          ? _buildPaidCelebrationView(payeeName, amount, invoiceNumber, currencyFormatter)
          : _buildActiveQrView(
              upiId,
              payeeName,
              amount,
              invoiceNumber,
              upiString,
              currencyFormatter,
            ),
    );
  }

  Widget _buildActiveQrView(
    String upiId,
    String payeeName,
    double amount,
    String? invoiceNumber,
    String upiString,
    dynamic currencyFormatter,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Drag Handle
        Container(
          width: 38,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 18),

        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'UPI Payment QR',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount > 0
                      ? 'Scan to pay ${currencyFormatter.format(amount)}'
                      : 'Scan with any UPI app to pay',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECE8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFF5722).withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFFF5722)),
                  SizedBox(width: 4),
                  Text(
                    'Instant UPI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF5722),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // App Selector Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildAppTab(UpiAppType.generic, 'All UPI', Icons.qr_code_2_rounded),
              const SizedBox(width: 8),
              _buildAppTab(UpiAppType.googlePay, 'Google Pay', Icons.account_balance_wallet_rounded),
              const SizedBox(width: 8),
              _buildAppTab(UpiAppType.phonePe, 'PhonePe', Icons.phone_android_rounded),
              const SizedBox(width: 8),
              _buildAppTab(UpiAppType.paytm, 'Paytm', Icons.payments_rounded),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // QR Code Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              QrImageView(
                data: upiString,
                version: QrVersions.auto,
                size: 180.0,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF0F172A),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_circle_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      payeeName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (amount > 0) ...[
                      const Text(' • ', style: TextStyle(color: Color(0xFF64748B))),
                      Text(
                        currencyFormatter.format(amount),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFF5722),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Copy UPI ID Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.alternate_email_rounded, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        upiId,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: upiId));
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Copied UPI ID: $upiId'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECE8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Copy',
                    style: TextStyle(
                      color: Color(0xFFFF5722),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Action Buttons Row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final qrBytes = await PaymentQrService.generateQrImageBytes(data: upiString);
                  if (qrBytes != null) {
                    await Printing.sharePdf(
                      bytes: qrBytes,
                      filename: 'UPI_QR_${payeeName.replaceAll(' ', '_')}.png',
                    );
                  }
                },
                icon: const Icon(Icons.share_rounded, size: 18, color: Color(0xFF0F172A)),
                label: const Text('Share QR', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final launched = await PaymentQrService.launchPayment(
                    upiId: upiId,
                    payeeName: payeeName,
                    amount: amount > 0 ? amount : null,
                    invoiceNumber: invoiceNumber,
                    appType: _selectedApp,
                  );
                  if (!launched && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No supported UPI app found. Please scan the QR code.'),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 18, color: Colors.white),
                label: const Text('Open UPI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),

        if (widget.invoice != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton.icon(
              onPressed: _isMarkingPaid ? null : _handleMarkAsPaid,
              icon: _isMarkingPaid
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                    )
                  : const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 18),
              label: Text(
                _isMarkingPaid ? 'Updating...' : 'Mark Payment as Received',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaidCelebrationView(
    String payeeName,
    double amount,
    String? invoiceNumber,
    dynamic currencyFormatter,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF10B981), width: 3),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF10B981),
              size: 46,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Payment Received!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        if (amount > 0)
          Text(
            currencyFormatter.format(amount),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF10B981),
            ),
          ),
        const SizedBox(height: 4),
        if (invoiceNumber != null)
          Text(
            'Invoice #$invoiceNumber marked as Paid',
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5722),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text(
              'Done',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppTab(UpiAppType type, String label, IconData icon) {
    final isSelected = _selectedApp == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedApp = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFECE8) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF5722) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? const Color(0xFFFF5722) : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? const Color(0xFFFF5722) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
