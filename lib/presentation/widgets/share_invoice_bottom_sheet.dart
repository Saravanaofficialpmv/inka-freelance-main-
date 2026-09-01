import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/business_profile.dart';
import '../../data/models/invoice.dart';
import '../../services/pdf_service.dart';
import '../../services/whatsapp_service.dart';

class ShareInvoiceBottomSheet extends StatefulWidget {
  final Invoice invoice;
  final BusinessProfile profile;

  const ShareInvoiceBottomSheet({
    super.key,
    required this.invoice,
    required this.profile,
  });

  static Future<void> show(
    BuildContext context, {
    required Invoice invoice,
    required BusinessProfile profile,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ShareInvoiceBottomSheet(
        invoice: invoice,
        profile: profile,
      ),
    );
  }

  @override
  State<ShareInvoiceBottomSheet> createState() => _ShareInvoiceBottomSheetState();
}

class _ShareInvoiceBottomSheetState extends State<ShareInvoiceBottomSheet> {
  late WhatsAppTemplateType _selectedTemplate;
  late TextEditingController _messageController;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    if (widget.invoice.status == 'paid') {
      _selectedTemplate = WhatsAppTemplateType.paymentReceipt;
    } else if (DateTime.now().isAfter(widget.invoice.dueDate)) {
      _selectedTemplate = WhatsAppTemplateType.overdueNotice;
    } else {
      _selectedTemplate = WhatsAppTemplateType.newInvoice;
    }

    _messageController = TextEditingController(
      text: WhatsAppService.buildMessage(
        invoice: widget.invoice,
        profile: widget.profile,
        templateType: _selectedTemplate,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _onTemplateChanged(WhatsAppTemplateType type) {
    setState(() {
      _selectedTemplate = type;
      _messageController.text = WhatsAppService.buildMessage(
        invoice: widget.invoice,
        profile: widget.profile,
        templateType: _selectedTemplate,
      );
    });
  }

  Future<void> _handleSendWhatsApp() async {
    final clientPhone = widget.invoice.client.phone;
    if (clientPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Client phone number is empty. Please add a phone number to client details.'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    final success = await WhatsAppService.sendWhatsAppMessage(
      phoneNumber: clientPhone,
      message: _messageController.text,
    );
    if (mounted) {
      setState(() => _isSending = false);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open WhatsApp. Please check if WhatsApp is installed.'),
            backgroundColor: const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _handleCopyMessage() {
    Clipboard.setData(ClipboardData(text: _messageController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Message copied to clipboard!'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientPhone = widget.invoice.client.phone;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Handle Bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title & Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Share & Remind Client',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Invoice #${widget.invoice.invoiceNumber} • ${widget.invoice.client.name}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quick Actions: Direct PDF Share & Print
            Row(
              children: [
                Expanded(
                  child: _ActionPill(
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'Share PDF File',
                    color: const Color(0xFFF8FAFC),
                    textColor: const Color(0xFFFF5722),
                    onTap: () {
                      Navigator.of(context).pop();
                      PdfService.shareInvoice(widget.invoice, widget.profile);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionPill(
                    icon: Icons.print_rounded,
                    label: 'Print / Save',
                    color: const Color(0xFFF8FAFC),
                    textColor: const Color(0xFF0F172A),
                    onTap: () {
                      Navigator.of(context).pop();
                      PdfService.printInvoice(widget.invoice, widget.profile);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Template Selector Chips
            const Text(
              'Select Message Template',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _TemplateChip(
                    label: '📄 New Invoice',
                    isSelected: _selectedTemplate == WhatsAppTemplateType.newInvoice,
                    onTap: () => _onTemplateChanged(WhatsAppTemplateType.newInvoice),
                  ),
                  const SizedBox(width: 8),
                  _TemplateChip(
                    label: '⏳ Friendly Reminder',
                    isSelected: _selectedTemplate == WhatsAppTemplateType.friendlyReminder,
                    onTap: () => _onTemplateChanged(WhatsAppTemplateType.friendlyReminder),
                  ),
                  const SizedBox(width: 8),
                  _TemplateChip(
                    label: '⚠️ Overdue Notice',
                    isSelected: _selectedTemplate == WhatsAppTemplateType.overdueNotice,
                    onTap: () => _onTemplateChanged(WhatsAppTemplateType.overdueNotice),
                  ),
                  const SizedBox(width: 8),
                  _TemplateChip(
                    label: '🎉 Paid Receipt',
                    isSelected: _selectedTemplate == WhatsAppTemplateType.paymentReceipt,
                    onTap: () => _onTemplateChanged(WhatsAppTemplateType.paymentReceipt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Message Preview & Editor
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Message Preview (Editable)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                TextButton.icon(
                  onPressed: _handleCopyMessage,
                  icon: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFFFF5722)),
                  label: const Text(
                    'Copy Text',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFF5722)),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 7,
                style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A), height: 1.45),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(14),
                  border: InputBorder.none,
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Primary WhatsApp Dispatch CTA Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(27),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF25D366).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSending ? null : _handleSendWhatsApp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        clientPhone.isNotEmpty
                            ? 'Send to WhatsApp ($clientPhone)'
                            : 'Send to WhatsApp',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
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

class _TemplateChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TemplateChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFECE8) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF5722) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? const Color(0xFFFF5722) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
