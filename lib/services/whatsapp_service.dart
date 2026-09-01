import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/models/business_profile.dart';
import '../data/models/invoice.dart';
import 'currency_tax_service.dart';

enum WhatsAppTemplateType {
  newInvoice,
  friendlyReminder,
  overdueNotice,
  paymentReceipt,
}

class WhatsAppService {
  /// Generates a personalized text message according to the chosen template type.
  static String buildMessage({
    required Invoice invoice,
    required BusinessProfile profile,
    required WhatsAppTemplateType templateType,
  }) {
    final currencyFormat = CurrencyTaxService.getCurrencyFormatter(
      currencyCode: profile.currency,
      decimalDigits: 2,
    );
    final totalFormatted = currencyFormat.format(invoice.total);
    final dueFormatted = DateFormat('dd MMM yyyy').format(invoice.dueDate);
    final issueFormatted = DateFormat('dd MMM yyyy').format(invoice.issueDate);
    final clientName = invoice.client.name.isNotEmpty ? invoice.client.name : 'Valued Client';
    final businessName = profile.businessName.isNotEmpty ? profile.businessName : 'Our Business';

    switch (templateType) {
      case WhatsAppTemplateType.newInvoice:
        return '👋 Hello *$clientName*,\n\n'
            'Thank you for your business! Here are the details for your new invoice from *$businessName*:\n\n'
            '📄 *Invoice Number:* #${invoice.invoiceNumber}\n'
            '📅 *Issue Date:* $issueFormatted\n'
            '⏳ *Due Date:* $dueFormatted\n'
            '💰 *Total Amount Due:* *$totalFormatted*\n'
            '${_buildItemsSummary(invoice)}'
            '${_buildPaymentDetails(profile)}'
            'Please let us know once the payment is completed. Let us know if you have any questions!\n\n'
            'Best regards,\n*$businessName*';

      case WhatsAppTemplateType.friendlyReminder:
        return '👋 Hi *$clientName*,\n\n'
            'This is a friendly reminder regarding invoice *#${invoice.invoiceNumber}* from *$businessName*.\n\n'
            '💰 *Amount Due:* *$totalFormatted*\n'
            '⏳ *Due Date:* $dueFormatted\n'
            '${_buildPaymentDetails(profile)}'
            'If you have already processed this payment, please disregard this note. Thank you!\n\n'
            'Warm regards,\n*$businessName*';

      case WhatsAppTemplateType.overdueNotice:
        return '⚠️ *Payment Overdue Notice*\n\n'
            'Dear *$clientName*,\n\n'
            'Our records indicate that invoice *#${invoice.invoiceNumber}* for *$totalFormatted* was due on *$dueFormatted* and remains outstanding.\n\n'
            '${_buildPaymentDetails(profile)}'
            'Kindly settle this invoice at your earliest convenience. If you need any assistance or have already made the transfer, please reply to this message.\n\n'
            'Sincerely,\n*$businessName*';

      case WhatsAppTemplateType.paymentReceipt:
        return '🎉 *Payment Received - Thank You!*\n\n'
            'Dear *$clientName*,\n\n'
            'We are pleased to confirm receipt of your payment for invoice *#${invoice.invoiceNumber}*.\n\n'
            '💰 *Amount Settled:* *$totalFormatted*\n'
            '📅 *Date:* ${DateFormat('dd MMM yyyy').format(DateTime.now())}\n'
            '✅ *Status:* Paid in Full\n\n'
            'We truly appreciate doing business with you and look forward to collaborating again soon!\n\n'
            'Best regards,\n*$businessName*';
    }
  }

  static String _buildItemsSummary(Invoice invoice) {
    if (invoice.items.isEmpty) return '\n';
    final buffer = StringBuffer('\n📦 *Summary of Services/Items:*\n');
    for (int i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      buffer.writeln('• ${item.name} (${item.quantity}x)');
    }
    buffer.writeln();
    return buffer.toString();
  }

  static String _buildPaymentDetails(BusinessProfile profile) {
    if ((profile.upiId == null || profile.upiId!.isEmpty) &&
        (profile.accountNo == null || profile.accountNo!.isEmpty)) {
      return '\n';
    }

    final buffer = StringBuffer('💳 *Payment Information:*\n');
    if (profile.upiId != null && profile.upiId!.isNotEmpty) {
      buffer.writeln('• *UPI ID:* ${profile.upiId}');
    }
    if (profile.accountNo != null && profile.accountNo!.isNotEmpty) {
      buffer.writeln('• *Bank:* ${profile.bankName ?? ''} | *A/C:* ${profile.accountNo}');
      if (profile.ifscCode != null && profile.ifscCode!.isNotEmpty) {
        buffer.writeln('• *IFSC / Routing:* ${profile.ifscCode}');
      }
    }
    buffer.writeln();
    return buffer.toString();
  }

  /// Sanitizes phone numbers and opens WhatsApp with the specified message.
  static Future<bool> sendWhatsAppMessage({
    required String phoneNumber,
    required String message,
  }) async {
    final sanitizedNumber = _sanitizePhoneNumber(phoneNumber);
    final encodedMessage = Uri.encodeComponent(message);

    // 1. Try native WhatsApp URL scheme
    final nativeUri = Uri.parse('whatsapp://send?phone=$sanitizedNumber&text=$encodedMessage');
    if (await canLaunchUrl(nativeUri)) {
      return await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
    }

    // 2. Fallback to universal web link (wa.me)
    final webUri = Uri.parse(
      sanitizedNumber.isNotEmpty
          ? 'https://wa.me/$sanitizedNumber?text=$encodedMessage'
          : 'https://wa.me/?text=$encodedMessage',
    );

    if (await canLaunchUrl(webUri)) {
      return await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }

    return false;
  }

  static String _sanitizePhoneNumber(String rawNumber) {
    // Strip everything except digits and leading +
    String cleaned = rawNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }
    return cleaned;
  }
}
