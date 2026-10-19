import '../data/models/business_profile.dart';
import '../data/models/invoice.dart';
import 'currency_tax_service.dart';

/// Dart generator that produces the exact self-contained HTML/CSS invoice documents
/// corresponding to the 14 React + TypeScript reference templates.
/// This HTML can be directly used for WebView previews or converted to PDF via Printing.convertHtml.
class ReactInvoiceHtmlGenerator {
  /// Generates the complete HTML document for any of the 14 template IDs.
  static String generateHtml(
    Invoice invoice,
    BusinessProfile profile, {
    String? templateId,
  }) {
    final effectiveId = (templateId != null && templateId.isNotEmpty)
        ? templateId
        : (profile.invoiceTemplate.isNotEmpty
              ? profile.invoiceTemplate
              : 'template_classic');

    final currencyFmt = CurrencyTaxService.getCurrencyFormatter(
      currencyCode: profile.currency.isNotEmpty ? profile.currency : 'INR',
      decimalDigits: 2,
    );

    final subtotalStr = currencyFmt.format(invoice.subtotal);
    final totalStr = currencyFmt.format(invoice.total);
    final taxStr = currencyFmt.format(invoice.taxAmount);
    final discountStr = currencyFmt.format(invoice.discount);

    // Header color based on template reference
    final headerColor = _getHeaderColor(effectiveId);

    final rowsHtml = StringBuffer();
    for (int i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      final itemRate = currencyFmt.format(item.price);
      final itemTotal = currencyFmt.format(item.total);

      rowsHtml.write('''
        <tr style="border-bottom: 1px solid #E2E8F0;">
          <td style="text-align: center; padding: 6px 4px; color: #64748B;">${i + 1}</td>
          <td style="padding: 6px 8px;">
            <div style="font-weight: 700; color: #0F172A;">${_escape(item.name)}</div>
          </td>
          <td style="text-align: center; font-family: monospace; padding: 6px 4px; color: #475569;">-</td>
          <td style="text-align: right; padding: 6px 6px;">$itemRate</td>
          <td style="text-align: center; padding: 6px 4px;">${item.quantity}</td>
          <td style="text-align: right; font-weight: 700; color: #0F172A; padding: 6px 8px;">$itemTotal</td>
        </tr>
      ''');
    }

    final client = invoice.client;

    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Invoice - ${_escape(invoice.invoiceNumber)}</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    @page { size: A4 portrait; margin: 10mm; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif;
      color: #0F172A;
      background: #FFFFFF;
      line-height: 1.4;
      font-size: 8.5px;
      -webkit-print-color-adjust: exact !important;
      print-color-adjust: exact !important;
    }
    .invoice-page { width: 100%; max-width: 190mm; margin: 0 auto; background: #FFFFFF; }
    table { width: 100%; border-collapse: collapse; }
    .header-box { display: flex; justify-content: space-between; align-items: flex-start; padding-bottom: 12px; border-bottom: 2px solid $headerColor; }
    .parties-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; padding: 10px 0; border-bottom: 1px solid #E2E8F0; }
    .table-head { background-color: $headerColor; color: #FFFFFF; font-weight: 700; }
    .totals-table td { padding: 3px 6px; }
  </style>
</head>
<body>
  <div class="invoice-page">
    <!-- Header -->
    <div class="header-box">
      <div>
        <h1 style="font-size: 16px; font-weight: 800; color: #0F172A;">${_escape(profile.businessName)}</h1>
        ${profile.gstNumber != null && profile.gstNumber!.isNotEmpty ? '<div style="font-weight: 600; color: #334155; font-size: 8.5px; margin-top: 2px;">GSTIN: <span style="font-family: monospace;">${_escape(profile.gstNumber!)}</span></div>' : ''}
        <div style="color: #64748B; font-size: 8px; margin-top: 2px;">
          ${profile.address.isNotEmpty ? '<div>${_escape(profile.address)}</div>' : ''}
          ${profile.phone.isNotEmpty ? '<div>Tel: ${_escape(profile.phone)}</div>' : ''}
          ${profile.email.isNotEmpty ? '<div>Email: ${_escape(profile.email)}</div>' : ''}
        </div>
      </div>
      <div style="text-align: right;">
        <div style="font-size: 14px; font-weight: 900; color: $headerColor; letter-spacing: 0.05em; text-transform: uppercase;">TAX INVOICE</div>
        <div style="font-size: 7.5px; font-weight: 700; color: #94A3B8; margin-bottom: 4px;">ORIGINAL FOR RECIPIENT</div>
        <div><span style="color: #64748B;">Invoice #: </span><span style="font-weight: 700;">${_escape(invoice.invoiceNumber)}</span></div>
        <div><span style="color: #64748B;">Date: </span><span>${_formatDate(invoice.issueDate)}</span></div>
        <div><span style="color: #64748B;">Due Date: </span><span>${_formatDate(invoice.dueDate)}</span></div>
      </div>
    </div>

    <!-- Parties -->
    <div class="parties-grid">
      <div>
        <div style="font-size: 7.5px; font-weight: 700; color: #64748B; text-transform: uppercase; margin-bottom: 2px;">Billed To:</div>
        <div style="font-size: 11px; font-weight: 700; color: #0F172A;">${_escape(client.name)}</div>
        ${client.email.isNotEmpty ? '<div>Email: ${_escape(client.email)}</div>' : ''}
        ${client.phone.isNotEmpty ? '<div>Ph: ${_escape(client.phone)}</div>' : ''}
        ${client.address.isNotEmpty ? '<div style="color: #475569; margin-top: 2px;">${_escape(client.address)}</div>' : ''}
      </div>
      <div>
        <div style="font-size: 7.5px; font-weight: 700; color: #64748B; text-transform: uppercase; margin-bottom: 2px;">Shipped To:</div>
        <div style="font-weight: 700; color: #0F172A;">${_escape(client.name)}</div>
        <div style="color: #475569; margin-top: 2px;">${client.address.isNotEmpty ? _escape(client.address) : 'Same as billing address'}</div>
      </div>
    </div>

    <!-- Items Table -->
    <table style="margin: 12px 0;">
      <thead>
        <tr class="table-head">
          <th style="width: 5%; text-align: center; padding: 6px 4px;">#</th>
          <th style="width: 45%; text-align: left; padding: 6px 8px;">Item Description</th>
          <th style="width: 15%; text-align: center; padding: 6px 4px;">HSN/SAC</th>
          <th style="width: 12%; text-align: right; padding: 6px 6px;">Rate</th>
          <th style="width: 8%; text-align: center; padding: 6px 4px;">Qty</th>
          <th style="width: 15%; text-align: right; padding: 6px 8px;">Amount</th>
        </tr>
      </thead>
      <tbody>
        ${rowsHtml.toString()}
      </tbody>
    </table>

    <!-- Totals & Banking -->
    <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-top: 8px;">
      <div style="width: 58%; padding-right: 16px;">
        ${profile.bankName != null && profile.bankName!.isNotEmpty ? '''
          <div style="background: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 6px; padding: 8px; margin-bottom: 8px;">
            <div style="font-size: 7.5px; font-weight: 700; color: $headerColor; text-transform: uppercase; margin-bottom: 2px;">Bank Details:</div>
            <div><strong>Bank:</strong> ${_escape(profile.bankName!)}</div>
            ${profile.accountNo != null && profile.accountNo!.isNotEmpty ? '<div><strong>A/C No:</strong> <span style="font-family: monospace;">${_escape(profile.accountNo!)}</span></div>' : ''}
            ${profile.ifscCode != null && profile.ifscCode!.isNotEmpty ? '<div><strong>IFSC:</strong> <span style="font-family: monospace;">${_escape(profile.ifscCode!)}</span></div>' : ''}
            ${profile.branchName != null && profile.branchName!.isNotEmpty ? '<div><strong>Branch:</strong> ${_escape(profile.branchName!)}</div>' : ''}
          </div>
        ''' : ''}
      </div>

      <div style="width: 42%;">
        <table class="totals-table" style="text-align: right;">
          <tr>
            <td style="color: #64748B;">Subtotal:</td>
            <td style="font-weight: 600;">$subtotalStr</td>
          </tr>
          ${invoice.discount > 0 ? '''
            <tr>
              <td style="color: #DC2626;">Discount:</td>
              <td style="font-weight: 600; color: #DC2626;">-$discountStr</td>
            </tr>
          ''' : ''}
          ${invoice.taxAmount > 0 ? '''
            <tr>
              <td style="color: #64748B;">Tax (${invoice.taxPercentage.toStringAsFixed(1)}%):</td>
              <td style="font-weight: 600;">$taxStr</td>
            </tr>
          ''' : ''}
          <tr style="border-top: 2px solid $headerColor; border-bottom: 2px solid $headerColor;">
            <td style="padding: 6px 4px; font-weight: 800; font-size: 11px; text-transform: uppercase;">Total:</td>
            <td style="padding: 6px 4px; font-weight: 800; font-size: 13px; color: $headerColor;">$totalStr</td>
          </tr>
        </table>
      </div>
    </div>

    <!-- Signature & Notes -->
    <div style="display: flex; justify-content: space-between; align-items: flex-end; margin-top: 16px; padding-top: 12px; border-top: 1px solid #E2E8F0;">
      <div style="max-width: 320px; font-size: 7.5px; color: #64748B;">
        ${invoice.notes.isNotEmpty ? '<div><strong>Notes:</strong> ${_escape(invoice.notes)}</div>' : ''}
      </div>
      <div style="text-align: right; min-width: 140px;">
        <div style="font-size: 7.5px; font-weight: 600; color: #64748B;">For ${_escape(profile.businessName)}</div>
        <div style="height: 36px; display: flex; align-items: center; justify-content: flex-end;">
          <div style="border: 1px dashed #CBD5E1; border-radius: 50%; width: 36px; height: 36px; display: flex; align-items: center; justify-content: center; font-size: 6px; color: #94A3B8; text-transform: uppercase;">Seal</div>
        </div>
        <div style="font-size: 7px; color: #64748B;">Authorized Signatory</div>
      </div>
    </div>
  </div>
</body>
</html>''';
  }

  static String _getHeaderColor(String templateId) {
    switch (templateId) {
      case 'template_billto_shipto':
        return '#1E40AF';
      case 'template_classic':
        return '#003399';
      case 'template_compact':
        return '#18181B';
      case 'template_elegant':
        return '#111827';
      case 'template_elegant_images':
        return '#1F2937';
      case 'template_evergreen':
        return '#0D5C3A';
      case 'template_genz':
        return '#1A73E8';
      case 'template_legend':
        return '#0F2C59';
      case 'template_modern':
        return '#131921';
      case 'template_mrp_discount':
        return '#15803D';
      case 'template_professional':
        return '#1E3A8A';
      case 'template_service':
        return '#E1306C';
      case 'template_service_2':
        return '#004B6E';
      case 'template_vintage':
        return '#005A9C';
      default:
        return '#003399';
    }
  }

  static String _escape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
