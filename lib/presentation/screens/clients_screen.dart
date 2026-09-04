import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/client.dart';
import '../../data/models/invoice.dart';
import '../providers/client_provider.dart';
import '../providers/profile_provider.dart';
import '../viewmodels/invoice_viewmodel.dart';
import '../../services/currency_tax_service.dart';
import '../widgets/tibsy_refresh_icon.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/highlighted_text.dart';
import '../widgets/bouncing_button.dart';
import '../widgets/search_empty_state.dart';
import '../../services/contact_service.dart';
import '../../core/utils/validators.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  final bool isSelectionMode;

  const ClientsScreen({super.key, this.isSelectionMode = false});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  String _selectedFilter = 'Active';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditClientDialog({Client? client}) {
    final nameController = TextEditingController(text: client?.name ?? '');
    final emailController = TextEditingController(text: client?.email ?? '');
    final phoneController = TextEditingController(text: client?.phone ?? '');
    final addressController = TextEditingController(text: client?.address ?? '');
    final gstController = TextEditingController(text: client?.gstNumber ?? '');

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
              const SizedBox(height: 12),
              _buildModalInput('GST / Tax ID (Optional)', 'e.g. 29ABCDE1234F1Z5', gstController, Icons.badge_outlined),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Client name is required')));
                      return;
                    }
                    final email = emailController.text.trim();
                    final emailErr = AppValidators.validateOptionalEmail(email);
                    if (emailErr != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(emailErr)));
                      return;
                    }
                    final phone = phoneController.text.trim();
                    final phoneErr = AppValidators.validateOptionalPhone(phone);
                    if (phoneErr != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(phoneErr)));
                      return;
                    }
                    final newClient = Client(
                      id: client?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      email: email,
                      phone: phone,
                      address: addressController.text.trim(),
                      gstNumber: gstController.text.trim().isNotEmpty ? gstController.text.trim() : client?.gstNumber,
                    );
                    if (client == null) {
                      ref.read(clientProvider.notifier).addClient(newClient);
                    } else {
                      ref.read(clientProvider.notifier).updateClient(newClient);
                    }
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    client == null ? 'Add Client' : 'Save Changes',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
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
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5)),
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
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = c.name.toLowerCase().contains(q);
        final matchesEmail = c.email.toLowerCase().contains(q);
        final matchesPhone = c.phone.toLowerCase().contains(q);
        final matchesAddress = c.address.toLowerCase().contains(q);
        if (!matchesName && !matchesEmail && !matchesPhone && !matchesAddress) {
          return false;
        }
      }
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
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fixed Top Header Bar & Search Bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 0),
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
                      BouncingButton(
                        onTap: () => _showAddEditClientDialog(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF5722), Color(0xFFFF7A50)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF5722).withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.person_add_alt_1_rounded, size: 20, color: Colors.white),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── Search Bar ──
                  AppSearchBar(
                    controller: _searchController,
                    hintText: 'Search clients, company, email...',
                    onChanged: (v) => setState(() => _searchQuery = v),
                    onClear: () => setState(() => _searchQuery = ''),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Scrollable Body with Tibsy Pull-to-Refresh ──
            Expanded(
              child: TibsyPullToRefresh(
                padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 120.0),
                onRefresh: () => syncAndRefreshEntireApp(ref),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                _searchQuery.trim().isNotEmpty
                    ? SearchEmptyState(
                        query: _searchQuery,
                        itemType: 'clients',
                        onClear: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : Container(
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
                    childAspectRatio: 1.05,
                  ),
                  itemCount: filteredClients.length,
                  itemBuilder: (ctx, index) {
                    final client = filteredClients[index];
                    final clientInvoices = invoices.where((i) => i.client.id == client.id).toList();
                    final unpaidInvoices = clientInvoices.where((i) => i.status.toLowerCase() != 'paid').toList();
                    final unpaidBalance = unpaidInvoices.fold<double>(0, (sum, i) => sum + i.total);

                    return GestureDetector(
                      onTap: () {
                        if (widget.isSelectionMode) {
                          context.pop(client);
                        } else {
                          context.push('/client-details', extra: client);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(13),
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
                                  radius: 18,
                                  backgroundColor: const Color(0xFF0F172A),
                                  child: Text(
                                    client.name.isNotEmpty ? client.name[0].toUpperCase() : 'C',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                _buildClientBalanceBadge(clientInvoices, unpaidBalance, currencyFormat),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      HighlightedText(
                                        text: client.name,
                                        query: _searchQuery,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13.5,
                                          color: Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${clientInvoices.length} Invoices',
                                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () => ContactService.makeCall(context, client.phone),
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFECE8),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFFFF5722).withValues(alpha: 0.2)),
                                        ),
                                        child: const Icon(Icons.phone_rounded, size: 13.5, color: Color(0xFFFF5722)),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => ContactService.openWhatsApp(context, client.phone),
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFECFDF5),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                                        ),
                                        child: const Icon(Icons.chat_rounded, size: 13.5, color: Color(0xFF10B981)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
    ],
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
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = label);
      },
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

  Widget _buildClientBalanceBadge(List<Invoice> clientInvoices, double unpaidBalance, dynamic currencyFormat) {
    if (clientInvoices.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text(
          'New',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
          ),
        ),
      );
    }

    if (unpaidBalance > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1ED),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFF5722).withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5722).withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          '${currencyFormat.format(unpaidBalance)} Due',
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFFFF5722),
            letterSpacing: -0.2,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 10, color: Color(0xFF10B981)),
          SizedBox(width: 3),
          Text(
            'All Clear',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF10B981),
              letterSpacing: -0.2,
            ),
          ),
        ],
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


