import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/models/invoice.dart';
import 'package:intl/intl.dart';

import '../data/models/business_profile.dart';

class PdfService {
  static Future<Uint8List> generateInvoicePdf(Invoice invoice, BusinessProfile profile) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.simpleCurrency(name: profile.currency, decimalDigits: 2);

    pw.MemoryImage? logoImage;
    if (!kIsWeb && profile.logoUrl != null && profile.logoUrl!.isNotEmpty) {
      try {
        final file = File(profile.logoUrl!);
        if (file.existsSync()) {
          logoImage = pw.MemoryImage(file.readAsBytesSync());
        }
      } catch (e) {
        debugPrint('Logo load error: $e');
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdf_lib.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // --- HEADER ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('TAX INVOICE',
                        style: pw.TextStyle(
                            color: pdf_lib.PdfColors.blue900,
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(profile.businessName.toUpperCase(),
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    if (profile.gstNumber != null && profile.gstNumber!.isNotEmpty)
                      pw.Text('GSTIN ${profile.gstNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.SizedBox(height: 2),
                    pw.SizedBox(
                      width: 250,
                      child: pw.Text(profile.address, style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Text('Mobile ${profile.phone}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Email ${profile.email}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('ORIGINAL FOR RECIPIENT', style: const pw.TextStyle(fontSize: 8, color: pdf_lib.PdfColors.grey700)),
                    pw.SizedBox(height: 8),
                    if (logoImage != null)
                      pw.Image(logoImage, height: 50)
                    else
                      pw.Container(
                        width: 80,
                        height: 40,
                        color: pdf_lib.PdfColors.grey300,
                        alignment: pw.Alignment.center,
                        child: pw.Text('LOGO', style: const pw.TextStyle(fontSize: 8)),
                      ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 1, color: pdf_lib.PdfColors.grey300),
            
            // --- INVOICE META ---
            pw.Row(
              children: [
                _buildMetaItem('Invoice #:', invoice.invoiceNumber),
                _buildMetaItem('Invoice Date:', DateFormat('dd MMM yyyy').format(invoice.issueDate)),
                _buildMetaItem('Due Date:', DateFormat('dd MMM yyyy').format(invoice.dueDate)),
              ],
            ),
            pw.Divider(thickness: 1, color: pdf_lib.PdfColors.grey300),

            // --- PARTY DETAILS ---
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _buildPartySection('Customer Details:', [
                    invoice.client.name,
                    'Ph: ${invoice.client.phone}',
                    if (invoice.client.gstNumber != null && invoice.client.gstNumber!.isNotEmpty)
                      'GSTIN: ${invoice.client.gstNumber}',
                  ]),
                ),
                pw.Expanded(
                  child: _buildPartySection('Billing address:', [
                    invoice.client.address,
                  ]),
                ),
                pw.Expanded(
                  child: _buildPartySection('Shipping address:', [
                    invoice.client.address, // Assuming same for now
                  ]),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text('Place of Supply: 09-UTTARPRADESH', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),

            // --- ITEMS TABLE ---
            pw.Table(
              border: pw.TableBorder.all(color: pdf_lib.PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FixedColumnWidth(25),
                1: pw.FlexColumnWidth(3),
                2: pw.FlexColumnWidth(1),
                3: pw.FixedColumnWidth(30),
                4: pw.FlexColumnWidth(1),
                5: pw.FlexColumnWidth(1),
                6: pw.FlexColumnWidth(1),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: pdf_lib.PdfColors.grey100),
                  children: [
                    _tableHeader('#'),
                    _tableHeader('Item'),
                    _tableHeader('Rate/ Item'),
                    _tableHeader('Qty'),
                    _tableHeader('Taxable Value'),
                    _tableHeader('Tax Amount'),
                    _tableHeader('Amount'),
                  ],
                ),
                // Rows
                ...invoice.items.asMap().entries.map((entry) {
                  final i = entry.key + 1;
                  final item = entry.value;
                  final taxableValue = item.price * item.quantity;
                  final taxPercentage = invoice.taxPercentage;
                  final taxAmount = taxableValue * (taxPercentage / 100);
                  
                  return pw.TableRow(
                    children: [
                      _tableCell(i.toString()),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(item.name, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                            pw.Text('HSN: 8517', style: const pw.TextStyle(fontSize: 7)), // Dummy HSN
                          ],
                        ),
                      ),
                      _tableCell(currencyFormat.format(item.price), align: pw.TextAlign.right),
                      _tableCell(item.quantity.toString(), align: pw.TextAlign.center),
                      _tableCell(currencyFormat.format(taxableValue), align: pw.TextAlign.right),
                      _tableCell('${currencyFormat.format(taxAmount)} ($taxPercentage%)', align: pw.TextAlign.right),
                      _tableCell(currencyFormat.format(taxableValue + taxAmount), align: pw.TextAlign.right),
                    ],
                  );
                }),
              ],
            ),

            // --- SUMMARY ---
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 8),
                      pw.Text('Total Items / Qty : ${invoice.items.length} / ${invoice.items.fold(0, (sum, i) => sum + i.quantity)}', style: const pw.TextStyle(fontSize: 8)),
                      pw.SizedBox(height: 12),
                      pw.Text('Total amount (in words):', style: const pw.TextStyle(fontSize: 8, color: pdf_lib.PdfColors.grey700)),
                      pw.Text('INR ${_numberToWords(invoice.total.toInt())} Only.', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Column(
                    children: [
                      _summaryRow('Taxable Amount', currencyFormat.format(invoice.subtotal)),
                      if (invoice.taxPercentage > 0)
                        _summaryRow('IGST ${invoice.taxPercentage}%', currencyFormat.format(invoice.taxAmount)),
                      pw.Container(
                        color: pdf_lib.PdfColors.grey100,
                        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                            pw.Text(currencyFormat.format(invoice.total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Amount Payable:', style: const pw.TextStyle(fontSize: 9, color: pdf_lib.PdfColors.grey700)),
                          pw.Text(currencyFormat.format(invoice.total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // --- PAYMENT & SIGNATORY ---
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Pay using UPI:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 8),
                    pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: profile.upiId != null && profile.upiId!.isNotEmpty 
                          ? 'upi://pay?pa=${profile.upiId}&pn=${Uri.encodeComponent(profile.businessName)}&am=${invoice.total}&cu=INR'
                          : 'upi://pay?pa=${profile.email.split("@")[0]}@okaxis&pn=${Uri.encodeComponent(profile.businessName)}&am=${invoice.total}&cu=INR',
                        width: 80,
                        height: 80,
                      ),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Bank Details:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      _bankRow('A/c Name:', profile.accountHolderName ?? profile.businessName),
                      _bankRow('Bank:', profile.bankName ?? 'Set in Profile'),
                      _bankRow('Account #:', profile.accountNo ?? 'Set in Profile'),
                      _bankRow('IFSC:', profile.ifscCode ?? 'Set in Profile'),
                      _bankRow('Branch:', profile.branchName ?? 'Set in Profile'),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('For ${profile.businessName}', style: pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 8),
                      if (!kIsWeb && profile.signatureUrl != null && profile.signatureUrl!.isNotEmpty && File(profile.signatureUrl!).existsSync())
                        pw.Image(
                          pw.MemoryImage(File(profile.signatureUrl!).readAsBytesSync()),
                          height: 50,
                        )
                      else
                        pw.Column(
                          children: [
                            pw.Container(
                              width: 70,
                              height: 40,
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: pdf_lib.PdfColors.grey400, width: 0.5, style: pw.BorderStyle.dashed),
                              ),
                              alignment: pw.Alignment.center,
                              child: pw.Text('SIGNATURE', style: const pw.TextStyle(fontSize: 6, color: pdf_lib.PdfColors.grey400)),
                            ),
                            pw.SizedBox(height: 4),
                          ],
                        ),
                      pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
              ],
            ),

            // --- FOOTER SECTION ---
            pw.SizedBox(height: 32),
            pw.Text('Notes:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            pw.Text(invoice.notes.isNotEmpty ? invoice.notes : 'Thank you for the Business', style: const pw.TextStyle(fontSize: 8)),
            pw.SizedBox(height: 12),
            pw.Text('Terms and Conditions:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            pw.Text('1. Goods once sold cannot be taken back or exchanged.', style: const pw.TextStyle(fontSize: 8)),
            pw.Text('2. We are not the manufacturers, company will stand for warranty as per their terms and conditions.', style: const pw.TextStyle(fontSize: 8)),
            pw.Text('3. Interest @24% p.a. will be charged for uncleared bills beyond 15 days.', style: const pw.TextStyle(fontSize: 8)),
            pw.Text('4. Subject to local Jurisdiction.', style: const pw.TextStyle(fontSize: 8)),
            
            pw.Spacer(),
            pw.Divider(thickness: 0.5, color: pdf_lib.PdfColors.grey300),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Page 1/1', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('This is a digitally signed document.', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildMetaItem(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(text: '$label ', style: const pw.TextStyle(fontSize: 9, color: pdf_lib.PdfColors.grey700)),
            pw.TextSpan(text: value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildPartySection(String title, List<String> details) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 9, color: pdf_lib.PdfColors.grey700)),
          pw.SizedBox(height: 4),
          ...details.map((d) => pw.Text(d, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
        ],
      ),
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      alignment: pw.Alignment.center,
      child: pw.Text(text, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _tableCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      alignment: align == pw.TextAlign.right ? pw.Alignment.centerRight : (align == pw.TextAlign.center ? pw.Alignment.center : pw.Alignment.centerLeft),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 8)),
    );
  }

  static pw.Widget _summaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: pdf_lib.PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _bankRow(String label, String value) {
    return pw.Row(
      children: [
        pw.SizedBox(width: 60, child: pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: pdf_lib.PdfColors.grey700))),
        pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static String _numberToWords(int number) {
    if (number == 0) return "Zero";
    var units = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"];
    var tens = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"];
    if (number < 20) return units[number];
    if (number < 100) return tens[number ~/ 10] + (number % 10 != 0 ? " ${units[number % 10]}" : "");
    if (number < 1000) return "${units[number ~/ 100]} Hundred${number % 100 != 0 ? " and ${_numberToWords(number % 100)}" : ""}";
    if (number < 1000000) return "${_numberToWords(number ~/ 1000)} Thousand${number % 1000 != 0 ? " ${_numberToWords(number % 1000)}" : ""}";
    return number.toString();
  }

  static Future<void> printInvoice(Invoice invoice, BusinessProfile profile) async {
    final pdfBytes = await generateInvoicePdf(invoice, profile);
    await Printing.layoutPdf(
      onLayout: (pdf_lib.PdfPageFormat format) async => pdfBytes,
      name: 'Invoice_${invoice.invoiceNumber}.pdf',
    );
  }

  static Future<void> shareInvoice(Invoice invoice, BusinessProfile profile) async {
    final pdfBytes = await generateInvoicePdf(invoice, profile);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Invoice_${invoice.invoiceNumber}.pdf',
    );
  }
}
