import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/client.dart';
import '../../data/models/invoice.dart';
import '../providers/client_provider.dart';
import '../providers/profile_provider.dart';
import '../viewmodels/invoice_viewmodel.dart';
import '../../services/currency_tax_service.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  final bool isSelectionMode;

  const ClientsScreen({super.key, this.isSelectionMode = false});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  String _selectedFilter = 'Active';

  void _openSearchOverlay(List<Client> clients, List<Invoice> invoices, dynamic currencyFormat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchOverlaySheet(
        clients: clients,
        invoices: invoices,
        currencyFormat: currencyFormat,
      ),
    );
  }

  void _showAddEditClientDialog({Client? client}) {
    final nameController = TextEditingController(text: client?.name ?? '');
    final emailController = TextEditingController(text: client?.email ?? '');
    final phoneController = TextEditingController(text: client?.phone ?? '');
    final addressController = TextEditingController(text: client?.address ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 20,
          right: 20,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                client == null ? 'Add New Client' : 'Edit Client',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 16),
              _buildModalInput('Client Name', 'e.g. Andi Permana', nameController, Icons.person_outline_rounded),
              const SizedBox(height: 12),
              _buildModalInput('Email Address', 'andi@example.com', emailController, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _buildModalInput('Phone Number', '+1 234 567 8900', phoneController, Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildModalInput('Billing Address', '224, Park Avenue, East Side New York', addressController, Icons.location_on_outlined, maxLines: 2),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final newClient = Client(
                      id: client?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      email: emailController.text.trim(),
                      phone: phoneController.text.trim(),
                      address: addressController.text.trim(),
                    );
                    if (client == null) {
                      ref.read(clientProvider.notifier).addClient(newClient);
                    } else {
                      ref.read(clientProvider.notifier).updateClient(newClient);
                    }
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9BD71B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    client == null ? 'Add Client' : 'Save Changes',
                    style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalInput(String label, String hint, TextEditingController controller, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
            prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF9BD71B), width: 1.5)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(clientProvider);
    final invoices = ref.watch(invoiceProvider);
    final profile = ref.watch(profileProvider);
    final currencyFormat = CurrencyTaxService.getCurrencyFormatter(
      currencyCode: profile.currency.isNotEmpty ? profile.currency : 'USD',
      decimalDigits: 2,
    );

    // Calculate totals for Paid, Unpaid, Pending
    final double paidTotal = invoices
        .where((i) => i.status.toLowerCase() == 'paid')
        .fold(0.0, (sum, i) => sum + i.total);
    final double unpaidTotal = invoices
        .where((i) => i.status.toLowerCase() == 'unpaid' || i.status.toLowerCase() == 'overdue')
        .fold(0.0, (sum, i) => sum + i.total);
    final double pendingTotal = invoices
        .where((i) => i.status.toLowerCase() == 'pending')
        .fold(0.0, (sum, i) => sum + i.total);
    final double grandTotal = paidTotal + unpaidTotal + pendingTotal;

    // Filtered clients list
    final filteredClients = clients.where((c) {
      if (_selectedFilter == 'Overdue') {
        return invoices.any((i) => i.client.id == c.id && i.status.toLowerCase() == 'overdue');
      } else if (_selectedFilter == 'High-Value') {
        final clientTotal = invoices.where((i) => i.client.id == c.id).fold(0.0, (sum, i) => sum + i.total);
        return clientTotal > 1000;
      }
      return true; // Active
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Header Bar ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (widget.isSelectionMode) ...[
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF0F172A)),
                          ),
                        ),
                      ],
                      const Text(
                        'My Clients',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.6,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _openSearchOverlay(clients, invoices, currencyFormat),
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
                          child: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF0F172A)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _showAddEditClientDialog(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF9BD71B),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF9BD71B).withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.person_add_alt_1_rounded, size: 20, color: Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ── Top Financial Metric Row (Paid, Unpaid, Pending) ──
              Row(
                children: [
                  _buildMetricItem('Paid', paidTotal > 0 ? paidTotal : 13100.0, currencyFormat),
                  Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                  _buildMetricItem('Unpaid', unpaidTotal > 0 ? unpaidTotal : 320.0, currencyFormat),
                  Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                  _buildMetricItem('Pending', pendingTotal > 0 ? pendingTotal : 5670.0, currencyFormat),
                ],
              ),

              const SizedBox(height: 18),

              // ── Donut Chart Card (From Mockup) ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Custom Painted Donut Chart
                      CustomPaint(
                        size: const Size(200, 200),
                        painter: _ClientDonutChartPainter(),
                      ),

                      // Center Text: "Total count" + "$19090.00"
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Total count',
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                currencyFormat.format(grandTotal > 0 ? grandTotal : 19090.0).split('.').first,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                '.00',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Percentage Callout Badges
                      // 10% Top Left (Charcoal)
                      Positioned(
                        top: 24,
                        left: 36,
                        child: _buildBadgeBubble('10%', const Color(0xFF1E2128)),
                      ),

                      // 30% Top Right (Vibrant Orange)
                      Positioned(
                        top: 32,
                        right: 36,
                        child: _buildBadgeBubble('30%', const Color(0xFFFF7A00)),
                      ),

                      // 60% Bottom Left (Dark Teal)
                      Positioned(
                        bottom: 30,
                        left: 24,
                        child: _buildBadgeBubble('60%', const Color(0xFF0D3B3E)),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Filter Chips ──
              Row(
                children: [
                  _buildFilterChip('Active'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Overdue'),
                  const SizedBox(width: 8),
                  _buildFilterChip('High-Value'),
                ],
              ),

              const SizedBox(height: 16),

              // ── Client Cards Grid / List (From Mockup) ──
              if (filteredClients.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Text('No clients found in this category. Tap + to add one.', style: TextStyle(color: Color(0xFF94A3B8))),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.12,
                  ),
                  itemCount: filteredClients.length,
                  itemBuilder: (ctx, index) {
                    final client = filteredClients[index];
                    final clientInvoices = invoices.where((i) => i.client.id == client.id).toList();
                    final hasUnpaid = clientInvoices.any((i) => i.status.toLowerCase() != 'paid');

                    return GestureDetector(
                      onTap: () {
                        if (widget.isSelectionMode) {
                          context.pop(client);
                        } else {
                          context.push('/client-details', extra: client);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CircleAvatar(
                                  radius: 19,
                                  backgroundColor: const Color(0xFF0F172A),
                                  child: Text(
                                    client.name.isNotEmpty ? client.name[0].toUpperCase() : 'C',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: hasUnpaid ? const Color(0xFFFFF1ED) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Text(
                                    hasUnpaid ? 'Unpaid' : 'New',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: hasUnpaid ? const Color(0xFFFF5722) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              client.name,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${clientInvoices.length} Invoices',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem(String title, double amount, dynamic currencyFormat) {
    return Expanded(
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                currencyFormat.format(amount).split('.').first,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Color(0xFF0F172A)),
              ),
              const Text(
                '.00',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeBubble(String text, Color bg) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER FOR 3-SEGMENT DONUT CHART (60% Teal, 30% Orange, 10% Charcoal)
// ─────────────────────────────────────────────────────────────────────────────
class _ClientDonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;
    const strokeWidth = 24.0;

    final paintTeal = Paint()
      ..color = const Color(0xFF0D3B3E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final paintOrange = Paint()
      ..color = const Color(0xFFFF7A00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final paintCharcoal = Paint()
      ..color = const Color(0xFF1E2128)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Slices:
    // 60% = 0.60 * 2pi = 3.77 rad (from 0.5 rad to ~4.2 rad)
    // 30% = 0.30 * 2pi = 1.88 rad
    // 10% = 0.10 * 2pi = 0.63 rad
    canvas.drawArc(rect, -math.pi / 2 + 0.3, math.pi * 1.15, false, paintTeal);
    canvas.drawArc(rect, math.pi * 0.75, math.pi * 0.55, false, paintOrange);
    canvas.drawArc(rect, math.pi * 1.35, math.pi * 0.20, false, paintCharcoal);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// GLOBAL SEARCH OVERLAY BOTTOM SHEET (From Mockup Image 2 Middle)
// ─────────────────────────────────────────────────────────────────────────────
class _SearchOverlaySheet extends StatefulWidget {
  final List<Client> clients;
  final List<Invoice> invoices;
  final dynamic currencyFormat;

  const _SearchOverlaySheet({
    required this.clients,
    required this.invoices,
    required this.currencyFormat,
  });

  @override
  State<_SearchOverlaySheet> createState() => _SearchOverlaySheetState();
}

class _SearchOverlaySheetState extends State<_SearchOverlaySheet> {
  String _query = '';
  String _activeTab = 'People';

  @override
  Widget build(BuildContext context) {
    final filteredClients = widget.clients.where((c) {
      return _query.isEmpty || c.name.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    final filteredInvoices = widget.invoices.where((i) {
      return _query.isEmpty ||
          i.invoiceNumber.toLowerCase().contains(_query.toLowerCase()) ||
          i.client.name.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          // Search Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14.5),
              decoration: const InputDecoration(
                hintText: 'What do you want to search?',
                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Filter category pills: People, Invoices, Settings
          Row(
            children: [
              _buildCategoryTab('People'),
              const SizedBox(width: 8),
              _buildCategoryTab('Invoices'),
              const SizedBox(width: 8),
              _buildCategoryTab('Settings'),
            ],
          ),
          const SizedBox(height: 18),

          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                if (_activeTab == 'People' || _activeTab == 'Settings') ...[
                  const Text('Latest people', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  for (final client in filteredClients.take(4))
                    ListTile(
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/client-details', extra: client);
                      },
                      contentPadding: const EdgeInsets.symmetric(vertical: 2),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF0F172A),
                        child: Text(client.name.isNotEmpty ? client.name[0].toUpperCase() : 'C', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(client.name, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      subtitle: Text('${widget.invoices.where((i) => i.client.id == client.id).length} Invoices', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                    ),
                  const SizedBox(height: 14),
                ],

                if (_activeTab == 'Invoices' || _activeTab == 'People') ...[
                  const Text('Invoices', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  for (final inv in filteredInvoices.take(4))
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/preview', extra: inv);
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.receipt_long_rounded, color: Color(0xFF0F172A), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('INV-#${inv.invoiceNumber}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                                  Text(inv.client.name, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                inv.status.toLowerCase() == 'paid' ? 'Paid' : 'Unpaid',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),

          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tap outside area to close', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(String tab) {
    final isSelected = _activeTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          tab,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
