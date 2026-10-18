import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../data/models/business_profile.dart';
import '../../data/models/invoice.dart';
import '../../services/pdf_service.dart';
import '../../services/whatsapp_service.dart';
import '../../services/currency_tax_service.dart';
import 'bouncing_button.dart';

class ShareInvoiceBottomSheet extends StatefulWidget {
  final Invoice invoice;
  final BusinessProfile profile;
  final String? templateId;

  const ShareInvoiceBottomSheet({
    super.key,
    required this.invoice,
    required this.profile,
    this.templateId,
  });

  static Future<void> show(
    BuildContext context, {
    required Invoice invoice,
    required BusinessProfile profile,
    String? templateId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ShareInvoiceBottomSheet(
        invoice: invoice,
        profile: profile,
        templateId: templateId,
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
  bool _isSharingPdf = false;

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
    HapticFeedback.selectionClick();
    setState(() {
      _selectedTemplate = type;
      _messageController.text = WhatsAppService.buildMessage(
        invoice: widget.invoice,
        profile: widget.profile,
        templateType: _selectedTemplate,
      );
    });
  }

  void _handleResetTemplate() {
    HapticFeedback.lightImpact();
    setState(() {
      _messageController.text = WhatsAppService.buildMessage(
        invoice: widget.invoice,
        profile: widget.profile,
        templateType: _selectedTemplate,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Template reset to default'),
        backgroundColor: Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _insertTag(String tagValue) {
    HapticFeedback.lightImpact();
    final text = _messageController.text;
    final selection = _messageController.selection;
    if (selection.isValid && selection.start >= 0 && selection.end <= text.length) {
      final newText = text.replaceRange(selection.start, selection.end, tagValue);
      _messageController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + tagValue.length),
      );
    } else {
      final newText = '$text $tagValue';
      _messageController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
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

  Future<void> _handleSharePdf() async {
    if (_isSharingPdf) return;
    setState(() => _isSharingPdf = true);
    HapticFeedback.lightImpact();

    try {
      await PdfService.shareInvoice(
        widget.invoice,
        widget.profile,
        templateId: widget.templateId,
      );
      if (mounted) {
        setState(() => _isSharingPdf = false);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSharingPdf = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share PDF: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientPhone = widget.invoice.client.phone;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: bottomInset + (bottomInset > 0 ? 16 : bottomPadding + 16),
        left: 20,
        right: 20,
        top: 14,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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
            const SizedBox(height: 14),

            // Header Title & Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Quick Actions: Direct PDF Share & Print
            Row(
              children: [
                Expanded(
                  child: _ActionPill(
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'Share PDF File',
                    color: const Color(0xFFF8FAFC),
                    textColor: const Color(0xFFFF5722),
                    isLoading: _isSharingPdf,
                    onTap: _isSharingPdf ? null : _handleSharePdf,
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
                      PdfService.printInvoice(widget.invoice, widget.profile, templateId: widget.templateId);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

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
                    label: '🤝 Formal Notice',
                    isSelected: _selectedTemplate == WhatsAppTemplateType.formalNotice,
                    onTap: () => _onTemplateChanged(WhatsAppTemplateType.formalNotice),
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

            // Message Preview & Editor Header
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
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _handleResetTemplate,
                      icon: const Icon(Icons.refresh_rounded, size: 13, color: Color(0xFF64748B)),
                      label: const Text(
                        'Reset',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: _handleCopyMessage,
                      icon: const Icon(Icons.copy_rounded, size: 13, color: Color(0xFFFF5722)),
                      label: const Text(
                        'Copy',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFFF5722)),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Quick Insert Placeholders Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _TagChip(
                    label: '+ Client',
                    onTap: () => _insertTag(widget.invoice.client.name.isNotEmpty ? widget.invoice.client.name : 'Client'),
                  ),
                  const SizedBox(width: 6),
                  _TagChip(
                    label: '+ Amount',
                    onTap: () {
                      final currencyFormat = CurrencyTaxService.getCurrencyFormatter(
                        currencyCode: widget.profile.currency,
                        decimalDigits: 2,
                      );
                      _insertTag(currencyFormat.format(widget.invoice.total));
                    },
                  ),
                  const SizedBox(width: 6),
                  _TagChip(
                    label: '+ Due Date',
                    onTap: () => _insertTag(DateFormat('dd MMM yyyy').format(widget.invoice.dueDate)),
                  ),
                  const SizedBox(width: 6),
                  _TagChip(
                    label: '+ Inv #',
                    onTap: () => _insertTag('#${widget.invoice.invoiceNumber}'),
                  ),
                  if (widget.profile.upiId != null && widget.profile.upiId!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _TagChip(
                      label: '+ UPI ID',
                      onTap: () => _insertTag('UPI: ${widget.profile.upiId}'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _messageController,
                minLines: 3,
                maxLines: 5,
                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), height: 1.4),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(12),
                  border: InputBorder.none,
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Primary WhatsApp Dispatch CTA Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: BouncingButton(
                onTap: _isSending ? null : _handleSendWhatsApp,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF25D366).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          clientPhone.isNotEmpty
                              ? 'Send to WhatsApp ($clientPhone)'
                              : 'Send to WhatsApp',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
  final VoidCallback? onTap;
  final bool isLoading;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            else
              Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 6),
            Text(
              isLoading ? 'Preparing...' : label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TagChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 13, color: Color(0xFFFF5722)),
            const SizedBox(width: 3),
            Text(
              label.replaceFirst('+ ', ''),
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
          ],
        ),
      ),
    );
  }
}
