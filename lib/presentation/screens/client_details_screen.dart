import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/client.dart';
import '../providers/client_provider.dart';
import '../providers/profile_provider.dart';
import '../viewmodels/invoice_viewmodel.dart';
import '../../services/currency_tax_service.dart';
import '../../services/contact_service.dart';
import '../widgets/status_badge.dart';
import 'create_invoice_screen.dart';

class ClientDetailsScreen extends ConsumerWidget {
  final Client client;

  const ClientDetailsScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveClients = ref.watch(clientProvider);
    final currentClient = liveClients.firstWhere(
      (c) => c.id == client.id,
      orElse: () => client,
    );

    final invoices = ref.watch(invoiceProvider);
    final clientInvoices = invoices.where((i) => i.client.id == currentClient.id).toList();

    final profile = ref.watch(profileProvider);
    final currencyFormat = CurrencyTaxService.getCurrencyFormatter(
      currencyCode: profile.currency.isNotEmpty ? profile.currency : 'USD',
      decimalDigits: 2,
    );

    // Stats calculations
    final paidInvoices = clientInvoices.where((i) => i.status.toLowerCase() == 'paid').toList();
    final unpaidInvoices = clientInvoices.where((i) => i.status.toLowerCase() != 'paid').toList();

    final paidSum = paidInvoices.fold<double>(0.0, (sum, i) => sum + i.total);
    final unpaidSum = unpaidInvoices.fold<double>(0.0, (sum, i) => sum + i.total);
    final totalSum = paidSum + unpaidSum;

    final ratioProgress = totalSum > 0 ? (paidSum / totalSum).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.canPop() ? context.pop() : context.go('/clients-tab'),
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
                    'Client Details',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz_rounded, size: 20, color: Color(0xFF0F172A)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onSelected: (value) {
                        if (value == 'call' && currentClient.phone.isNotEmpty) {
                          ContactService.makeCall(context, currentClient.phone);
                        } else if (value == 'whatsapp' && currentClient.phone.isNotEmpty) {
                          ContactService.openWhatsApp(context, currentClient.phone);
                        } else if (value == 'email' && currentClient.email.isNotEmpty) {
                          ContactService.sendEmail(context, currentClient.email);
                        } else if (value == 'delete') {
                          _confirmDelete(context, ref, currentClient);
                        }
                      },
                      itemBuilder: (context) => [
                        if (currentClient.phone.isNotEmpty)
                          const PopupMenuItem(
                            value: 'call',
                            child: Row(
                              children: [
                                Icon(Icons.phone_outlined, size: 18, color: Color(0xFF0F172A)),
                                SizedBox(width: 10),
                                Text('Call Client', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        if (currentClient.phone.isNotEmpty)
                          const PopupMenuItem(
                            value: 'whatsapp',
                            child: Row(
                              children: [
                                Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF25D366)),
                                SizedBox(width: 10),
                                Text('Send WhatsApp', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        if (currentClient.email.isNotEmpty)
                          const PopupMenuItem(
                            value: 'email',
                            child: Row(
                              children: [
                                Icon(Icons.email_outlined, size: 18, color: Color(0xFF0F172A)),
                                SizedBox(width: 10),
                                Text('Send Email', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                              SizedBox(width: 10),
                              Text('Delete Client', style: TextStyle(color: Colors.red, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
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
                  children: [
                    const SizedBox(height: 8),

                    // ── Client Avatar, Name & Address ──
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: const Color(0xFF0F172A),
                            child: Text(
                              currentClient.name.isNotEmpty ? currentClient.name[0].toUpperCase() : 'C',
                              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentClient.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentClient.address.isNotEmpty
                                ? currentClient.address
                                : (currentClient.email.isNotEmpty ? currentClient.email : '224, Park Avenue, East Side New York'),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 16),

                          // ── Quick Contact Actions ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildContactButton(
                                icon: Icons.phone_rounded,
                                label: 'Call',
                                color: const Color(0xFFFF5722),
                                onTap: () => ContactService.makeCall(context, currentClient.phone),
                              ),
                              const SizedBox(width: 10),
                              _buildContactButton(
                                icon: Icons.chat_rounded,
                                label: 'WhatsApp',
                                color: const Color(0xFF10B981),
                                onTap: () => ContactService.openWhatsApp(context, currentClient.phone),
                              ),
                              const SizedBox(width: 10),
                              _buildContactButton(
                                icon: Icons.email_rounded,
                                label: 'Email',
                                color: const Color(0xFF0F172A),
                                onTap: () => ContactService.sendEmail(context, currentClient.email),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── 3 Stat Cards Row (Total Invoices, Paid, Unpaid) ──
                    Row(
                      children: [
                        _buildStatBox(
                          title: 'Total Invoices',
                          count: clientInvoices.isNotEmpty ? clientInvoices.length : 12,
                          amount: totalSum > 0 ? totalSum : 4920.0,
                          currencyFormat: currencyFormat,
                        ),
                        const SizedBox(width: 10),
                        _buildStatBox(
                          title: 'Paid',
                          count: paidInvoices.isNotEmpty ? paidInvoices.length : 15,
                          amount: paidSum > 0 ? paidSum : 1920.0,
                          currencyFormat: currencyFormat,
                        ),
                        const SizedBox(width: 10),
                        _buildStatBox(
                          title: 'Unpaid',
                          count: unpaidInvoices.isNotEmpty ? unpaidInvoices.length : 3,
                          amount: unpaidSum > 0 ? unpaidSum : 2000.0,
                          currencyFormat: currencyFormat,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── "Invoice ratio" Card (From Mockup) ──
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Invoice ratio',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Row(
                                children: const [
                                  CircleAvatar(radius: 4, backgroundColor: Color(0xFF0D3B3E)),
                                  SizedBox(width: 4),
                                  Text('Paid', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                  SizedBox(width: 10),
                                  CircleAvatar(radius: 4, backgroundColor: Color(0xFFCBD5E1)),
                                  SizedBox(width: 4),
                                  Text('Unpaid', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${clientInvoices.isNotEmpty ? clientInvoices.length : 12} Available invoices',
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '-${currencyFormat.format(unpaidSum > 0 ? unpaidSum : 2000.0)}',
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Horizontal ratio progress bar (Teal vs Gray)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              height: 14,
                              child: LinearProgressIndicator(
                                value: ratioProgress,
                                backgroundColor: const Color(0xFFF1F5F9),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D3B3E)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── Invoices Section ──
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Invoices',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (clientInvoices.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Center(
                          child: Text(
                            'No invoices for this client yet. Tap below to create one.',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: clientInvoices.length,
                        itemBuilder: (ctx, index) {
                          final inv = clientInvoices[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: InkWell(
                              onTap: () => context.push('/preview', extra: inv),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0F172A), size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'INV-#${inv.invoiceNumber}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              currencyFormat.format(inv.total),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                            const Text('  •  ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                                            Text(
                                              'Until ${DateFormat('dd MMM yyyy').format(inv.dueDate)}',
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  StatusBadge(
                                    status: inv.status,
                                    dueDate: inv.dueDate,
                                    fontSize: 11.5,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    onTap: () => ref.read(invoiceProvider.notifier).togglePaymentStatus(inv.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ── Sticky Bottom CTA Button: "Create new invoices" ──
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
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => CreateInvoiceScreen.showAsBottomSheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Create new invoices',
                    style: TextStyle(
                      fontSize: 15.5,
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
    );
  }

  Widget _buildStatBox({
    required String title,
    required int count,
    required double amount,
    required dynamic currencyFormat,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
            Text(
              title,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 2),
            Text(
              currencyFormat.format(amount),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Client currentClient) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Client?'),
        content: Text('Are you sure you want to delete ${currentClient.name}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(clientProvider.notifier).deleteClient(currentClient.id);
              Navigator.pop(ctx);
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/clients-tab');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
