import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/theme_helper.dart';
import '../../data/models/invoice.dart';
import '../../data/models/payment_milestone.dart';

class PaymentProofSheet extends StatefulWidget {
  final Invoice invoice;
  final PaymentMilestone? milestone;
  final Function(String refNumber, String? note, String? imageBase64) onSubmit;

  const PaymentProofSheet({
    super.key,
    required this.invoice,
    this.milestone,
    required this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    required Invoice invoice,
    PaymentMilestone? milestone,
    required Function(String refNumber, String? note, String? imageBase64) onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentProofSheet(
        invoice: invoice,
        milestone: milestone,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<PaymentProofSheet> createState() => _PaymentProofSheetState();
}

class _PaymentProofSheetState extends State<PaymentProofSheet> {
  final _refController = TextEditingController();
  final _noteController = TextEditingController();
  final _picker = ImagePicker();
  String? _selectedImageBase64;
  String? _selectedImageName;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _refController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImageBase64 = base64Encode(bytes);
          _selectedImageName = picked.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking proof image: $e');
    }
  }

  void _handleSubmit() {
    final ref = _refController.text.trim();
    if (ref.isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a Transaction ID, UTR, or Reference Number.'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();
    widget.onSubmit(
      ref,
      _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      _selectedImageBase64,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: context.cardBorder),
      ),
      padding: EdgeInsets.only(
        bottom: bottomInset + (bottomInset > 0 ? 16 : bottomPadding + 16),
        left: 22,
        right: 22,
        top: 14,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: context.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Color(0xFF10B981),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Submit Proof of Payment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: context.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.milestone != null
                            ? 'For ${widget.milestone!.title}'
                            : 'Invoice #${widget.invoice.invoiceNumber}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // UTR / Reference Number Field
            Text(
              'TRANSACTION ID / UTR NUMBER *',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: context.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _refController,
              autofocus: true,
              style: TextStyle(
                color: context.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. UPI/1234567890 or IMPS-4920491',
                hintStyle: TextStyle(
                  color: context.textMuted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(Icons.tag_rounded, color: context.textSecondary, size: 20),
                filled: true,
                fillColor: context.surfaceHighlight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: context.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: context.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Optional Note / Sender name
            Text(
              'PAYMENT NOTE (OPTIONAL)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: context.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 2,
              style: TextStyle(
                color: context.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 13.5,
              ),
              decoration: InputDecoration(
                hintText: 'Sent from HDFC account ending in 8421...',
                hintStyle: TextStyle(
                  color: context.textMuted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                ),
                filled: true,
                fillColor: context.surfaceHighlight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: context.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: context.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Screenshot / Receipt Upload
            Text(
              'ATTACH PAYMENT SCREENSHOT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: context.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedImageBase64 != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.image_rounded, color: Color(0xFF10B981), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedImageName ?? 'Screenshot attached',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                      onPressed: () {
                        setState(() {
                          _selectedImageBase64 = null;
                          _selectedImageName = null;
                        });
                      },
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.textPrimary,
                        side: BorderSide(color: context.cardBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('From Gallery', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.textPrimary,
                        side: BorderSide(color: context.cardBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Submit Payment Confirmation",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
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
    );
  }
}

/// Modal for freelancer to review proof submitted by client
class ReviewProofDialog extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onVerifyPaid;

  const ReviewProofDialog({
    super.key,
    required this.invoice,
    required this.onVerifyPaid,
  });

  static Future<void> show(
    BuildContext context, {
    required Invoice invoice,
    required VoidCallback onVerifyPaid,
  }) {
    return showDialog(
      context: context,
      builder: (_) => ReviewProofDialog(
        invoice: invoice,
        onVerifyPaid: onVerifyPaid,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: context.cardBorder),
      ),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_outlined, color: Color(0xFFF59E0B), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Review Payment Proof',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.surfaceHighlight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('UTR / Reference:', style: TextStyle(fontSize: 12, color: context.textSecondary)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        invoice.paymentProofRef ?? 'N/A',
                        style: TextStyle(fontWeight: FontWeight.w900, color: context.textPrimary, fontSize: 13.5),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                if (invoice.paymentProofNote != null && invoice.paymentProofNote!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Client Note:', style: TextStyle(fontSize: 12, color: context.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    invoice.paymentProofNote!,
                    style: TextStyle(fontSize: 12.5, color: context.textPrimary, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Confirming this proof will update the invoice status to Paid and issue a verified receipt voucher.',
            style: TextStyle(fontSize: 12, color: context.textSecondary, height: 1.35),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close', style: TextStyle(color: context.textSecondary, fontWeight: FontWeight.w700)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onVerifyPaid();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: const Text('Verify & Mark Paid', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}
