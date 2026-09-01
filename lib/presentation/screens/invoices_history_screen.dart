import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../viewmodels/invoice_viewmodel.dart';
import '../providers/profile_provider.dart';
import '../../services/currency_tax_service.dart';
import '../../data/models/invoice.dart';
import 'create_invoice_screen.dart';

class InvoicesHistoryScreen extends ConsumerStatefulWidget {
  const InvoicesHistoryScreen({super.key});

  @override
  ConsumerState<InvoicesHistoryScreen> createState() => _InvoicesHistoryScreenState();
}

class _InvoicesHistoryScreenState extends ConsumerState<InvoicesHistoryScreen> {
  String _selectedStatusFilter = 'All';
  String _searchQuery = '';
  bool _isSearchOpen = false;

  void _showAdviceBottomSheet(List<Invoice> invoices, dynamic currencyFormat) {
    final unpaidInvoices = invoices.where((i) => i.status.toLowerCase() != 'paid').toList();
    final totalUnpaid = unpaidInvoices.fold<double>(0, (sum, i) => sum + i.total);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
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
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9BD71B).withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF7CB518), size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Invoice Health Advice',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Optimizations to get paid 3x faster',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildAdviceTile(
              icon: Icons.mark_chat_unread_outlined,
              title: 'Send WhatsApp Friendly Reminders',
              description: 'You have ${unpaidInvoices.length} unpaid invoices totaling ${currencyFormat.format(totalUnpaid)}. Sending an instant WhatsApp reminder with UPI QR can recover 70% of dues within 24 hours.',
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: 12),
            _buildAdviceTile(
              icon: Icons.timer_outlined,
              title: 'Shorten Payment Terms to 14 Days',
              description: 'Invoices with 14-day terms are paid 42% quicker than 30-day terms for freelancers.',
              color: const Color(0xFF007BFF),
            ),
            const SizedBox(height: 12),
            _buildAdviceTile(
              icon: Icons.qr_code_2_rounded,
              title: 'Include Instant Payment QR',
              description: 'Direct UPI/Bank QR on the invoice PDF eliminates friction for Indian and global clients.',
              color: const Color(0xFFFF7A00),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9BD71B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text(
                  'Got it, thanks!',
                  style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdviceTile({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoices = ref.watch(invoiceProvider);
    final profile = ref.watch(profileProvider);
    final currencyFormat = CurrencyTaxService.getCurrencyFormatter(
      currencyCode: profile.currency.isNotEmpty ? profile.currency : 'USD',
      decimalDigits: 2,
    );

    // Calculate metrics
    final unpaidCount = invoices.where((i) => i.status.toLowerCase() != 'paid').length;
    final paidCount = invoices.where((i) => i.status.toLowerCase() == 'paid').length;
    final totalCount = invoices.length;
    final healthScore = totalCount == 0 ? 100 : ((paidCount / totalCount) * 100).round().clamp(20, 100);

    // Unique favorite clients from recent invoices
    final Map<String, Invoice> clientRecentMap = {};
    for (final inv in invoices) {
      if (!clientRecentMap.containsKey(inv.client.id)) {
        clientRecentMap[inv.client.id] = inv;
      }
    }
    final favoriteClients = clientRecentMap.values.take(6).toList();

    // Filter invoices
    final filteredInvoices = invoices.where((inv) {
      final status = inv.status.toLowerCase();
      final filter = _selectedStatusFilter.toLowerCase();
      final matchesStatus = (filter == 'all') ||
          (filter == 'paid' && status == 'paid') ||
          (filter == 'unpaid' && (status == 'unpaid' || status == 'pending' || status == 'overdue')) ||
          (filter == 'drafts' && status == 'draft');

      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          inv.invoiceNumber.toLowerCase().contains(query) ||
          inv.client.name.toLowerCase().contains(query);

      return matchesStatus && matchesSearch;
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
                  const Text(
                    'My Invoices',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.6,
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _isSearchOpen = !_isSearchOpen),
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
                        onTap: () => CreateInvoiceScreen.showAsBottomSheet(context),
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
                          child: const Icon(Icons.add_rounded, size: 24, color: Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Search field toggle
              if (_isSearchOpen) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    autofocus: true,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Search invoice # or client name...',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search, color: Color(0xFF64748B), size: 18),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // ── Invoice Health Card (From Mockup) ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
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
                          'Invoice Health',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF94A3B8)),
                          onPressed: () => _showAdviceBottomSheet(invoices, currencyFormat),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$healthScore',
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -1,
                              ),
                            ),
                            const Text(
                              '/100',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$unpaidCount Unpaid Invoices',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── 8-Pill Color Health Meter with Floating Tooltip ──
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Row(
                          children: [
                            _buildHealthPill(const Color(0xFFEF4444)), // Bad
                            const SizedBox(width: 5),
                            _buildHealthPill(const Color(0xFFEF4444)), // Bad
                            const SizedBox(width: 5),
                            _buildHealthPill(const Color(0xFFF59E0B)), // Warning
                            const SizedBox(width: 5),
                            _buildHealthPill(const Color(0xFFF59E0B)), // Warning
                            const SizedBox(width: 5),
                            _buildHealthPill(const Color(0xFF007BFF)), // Good
                            const SizedBox(width: 5),
                            _buildHealthPill(const Color(0xFF007BFF)), // Good
                            const SizedBox(width: 5),
                            _buildHealthPill(const Color(0xFF10B981)), // Great
                            const SizedBox(width: 5),
                            _buildHealthPill(const Color(0xFF10B981)), // Great
                          ],
                        ),

                        // Tooltip indicator pill
                        Positioned(
                          top: -24,
                          left: MediaQuery.of(context).size.width * 0.44,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9BD71B),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$healthScore',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Scale Labels Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Text('Bad', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                        ),
                        Text('Warning', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                        Text('Good', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                        Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Text('Great', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // "Give me advice" Lime CTA Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => _showAdviceBottomSheet(invoices, currencyFormat),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9BD71B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Give me advice',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ── Favorite People Section ──
              const Text(
                'Favorite People',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 116,
                child: favoriteClients.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Center(
                          child: Text('Create your first invoice to see recent clients here.', style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8))),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: favoriteClients.length,
                        itemBuilder: (ctx, index) {
                          final inv = favoriteClients[index];
                          final clientInvoicesCount = invoices.where((i) => i.client.id == inv.client.id).length;
                          final hasUnpaid = invoices.any((i) => i.client.id == inv.client.id && i.status.toLowerCase() != 'paid');

                          return GestureDetector(
                            onTap: () => context.push('/client-details', extra: inv.client),
                            child: Container(
                              width: 175,
                              margin: const EdgeInsets.only(right: 12),
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
                                        radius: 18,
                                        backgroundColor: const Color(0xFF0F172A),
                                        child: Text(
                                          inv.client.name.isNotEmpty ? inv.client.name[0].toUpperCase() : 'C',
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
                                    inv.client.name,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$clientInvoicesCount Invoices',
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 22),

              // ── Invoices List Section ──
              const Text(
                'Invoices list',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),

              // Filter Tabs Row
              Row(
                children: [
                  _buildFilterTab('All', invoices.length),
                  const SizedBox(width: 8),
                  _buildFilterTab('Paid', invoices.where((i) => i.status.toLowerCase() == 'paid').length),
                  const SizedBox(width: 8),
                  _buildFilterTab('Unpaid', unpaidCount),
                  const SizedBox(width: 8),
                  _buildFilterTab('Drafts', invoices.where((i) => i.status.toLowerCase() == 'draft').length),
                ],
              ),

              const SizedBox(height: 14),

              // Invoices Cards List
              if (filteredInvoices.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 40, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 10),
                        const Text(
                          'No invoices found in this view',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        const Text('Tap + to create a new invoice instantly.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredInvoices.length,
                  itemBuilder: (ctx, index) {
                    final inv = filteredInvoices[index];
                    final isPaid = inv.status.toLowerCase() == 'paid';

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
                            // Left Icon Box
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0F172A), size: 20),
                            ),
                            const SizedBox(width: 12),

                            // Middle Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'INV-#${inv.invoiceNumber}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14.5,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Text(
                                        currencyFormat.format(inv.total),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12.5,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const Text('  •  ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                                      Text(
                                        'Until ${DateFormat('dd MMM yyyy').format(inv.dueDate)}',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Right Status Badge Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: isPaid ? const Color(0xFFECFDF5) : const Color(0xFFFFF1ED),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isPaid ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFFFF5722).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                isPaid ? 'Paid' : 'Unpaid',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isPaid ? const Color(0xFF10B981) : const Color(0xFFFF5722),
                                ),
                              ),
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

  Widget _buildHealthPill(Color color) {
    return Expanded(
      child: Container(
        height: 14,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(7),
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, int count) {
    final isSelected = _selectedStatusFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatusFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label == 'Drafts' ? 'Drafts $count' : label,
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
