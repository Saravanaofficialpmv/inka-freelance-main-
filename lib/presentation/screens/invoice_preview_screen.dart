import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/colors.dart';
import '../../data/models/invoice.dart';
import '../../services/pdf_service.dart';
import '../providers/profile_provider.dart';
import '../viewmodels/invoice_viewmodel.dart';

class InvoicePreviewScreen extends ConsumerWidget {
  final Invoice invoice;

  const InvoicePreviewScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final invoices = ref.watch(invoiceProvider);
    final currentInvoice = invoices.firstWhere((inv) => inv.id == invoice.id, orElse: () => invoice);
    final currencyFormat = NumberFormat.simpleCurrency(name: profile.currency, decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentInvoice.invoiceNumber),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => PdfService.shareInvoice(currentInvoice, profile),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => PdfService.printInvoice(currentInvoice, profile),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('INVOICE', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                          const SizedBox(height: 8),
                          Text('#${currentInvoice.invoiceNumber}', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Inka', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Text(DateFormat.yMMMd().format(currentInvoice.issueDate)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Billed To:', style: TextStyle(color: Colors.grey)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                           color: currentInvoice.status == 'paid' ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                           borderRadius: BorderRadius.circular(12)
                        ),
                        child: Text(
                           currentInvoice.status.toUpperCase(),
                           style: TextStyle(
                              color: currentInvoice.status == 'paid' ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                           ),
                        )
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(currentInvoice.client.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(currentInvoice.client.email),
                  Text(currentInvoice.client.phone),
                  Text(currentInvoice.client.address),
                  const SizedBox(height: 32),
                  const Divider(),
                  const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const Divider(),
                  ...currentInvoice.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text(item.name)),
                        Expanded(flex: 1, child: Text('${item.quantity}', textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text(currencyFormat.format(item.price), textAlign: TextAlign.right)),
                        Expanded(flex: 2, child: Text(currencyFormat.format(item.total), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  )),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SizedBox(width: 100, child: Text('Subtotal:', style: TextStyle(fontSize: 16, color: Colors.grey))),
                      SizedBox(width: 120, child: Text(currencyFormat.format(currentInvoice.subtotal), textAlign: TextAlign.right, style: const TextStyle(fontSize: 16))),
                    ],
                  ),
                  if (currentInvoice.taxPercentage > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(width: 100, child: Text('Tax (${currentInvoice.taxPercentage}%):', style: const TextStyle(fontSize: 16, color: Colors.grey))),
                          SizedBox(width: 120, child: Text(currencyFormat.format(currentInvoice.taxAmount), textAlign: TextAlign.right, style: const TextStyle(fontSize: 16))),
                        ],
                      ),
                    ),
                  if (currentInvoice.discount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const SizedBox(width: 100, child: Text('Discount:', style: TextStyle(fontSize: 16, color: Colors.grey))),
                          SizedBox(width: 120, child: Text('-${currencyFormat.format(currentInvoice.discount)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 16, color: Colors.red))),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SizedBox(width: 100, child: Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                      SizedBox(width: 120, child: Text(currencyFormat.format(currentInvoice.total), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFFF97316)))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ref.read(invoiceProvider.notifier).togglePaymentStatus(currentInvoice.id);
                        },
                        icon: Icon(currentInvoice.status == 'paid' ? Icons.close : Icons.check_circle),
                        label: Text(currentInvoice.status == 'paid' ? 'Mark Pending' : 'Mark Paid', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: currentInvoice.status == 'paid' ? AppColors.border : AppColors.success, width: 2),
                          foregroundColor: currentInvoice.status == 'paid' ? Colors.black : AppColors.success,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          fixedSize: const Size.fromHeight(58),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final text = 'Hello ${currentInvoice.client.name}, here is your latest invoice (${currentInvoice.invoiceNumber}) for ${currencyFormat.format(currentInvoice.total)}. Thank you for your business!';
                          final uri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          } else {
                            PdfService.shareInvoice(currentInvoice, profile);
                          }
                        },
                        icon: const Icon(Icons.send_rounded, color: Colors.white),
                        label: const Text('WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          fixedSize: const Size.fromHeight(58),
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
    );
  }
}
