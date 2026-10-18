import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/client.dart';
import '../providers/client_provider.dart';
import '../widgets/tibsy_refresh_icon.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/highlighted_text.dart';
import '../widgets/bouncing_button.dart';
import '../widgets/search_empty_state.dart';
import '../../services/contact_service.dart';
import '../widgets/device_contact_picker_sheet.dart';
import '../../core/utils/validators.dart';
import '../../core/theme/theme_helper.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  final bool isSelectionMode;

  const ClientsScreen({super.key, this.isSelectionMode = false});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
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
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 24,
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
              if (client == null) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final selected = await DeviceContactPickerSheet.show(context);
                    if (selected != null) {
                      nameController.text = selected.displayName;
                      if (selected.primaryPhone.isNotEmpty) {
                        phoneController.text = selected.primaryPhone;
                      }
                      if (selected.primaryEmail.isNotEmpty) {
                        emailController.text = selected.primaryEmail;
                      }
                      if (selected.address != null && selected.address!.isNotEmpty) {
                        addressController.text = selected.address!;
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.contacts_rounded, color: Color(0xFF2563EB), size: 18),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Import from Phone Contacts',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                'Auto-fill name, phone & email safely',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
                      ],
                    ),
                  ),
                ),
              ],
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
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    // Filtered clients list
    final filteredClients = clients.where((c) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = c.name.toLowerCase().contains(q);
        final matchesEmail = c.email.toLowerCase().contains(q);
        final matchesPhone = c.phone.toLowerCase().contains(q);
        final matchesAddress = c.address.toLowerCase().contains(q);
        return matchesName || matchesEmail || matchesPhone || matchesAddress;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
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
                      Expanded(
                        child: Row(
                          children: [
                            if (widget.isSelectionMode || Navigator.of(context).canPop()) ...[
                              GestureDetector(
                                onTap: () => context.pop(),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: context.circleBtnBg,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: context.cardBorder, width: 1.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: context.textPrimary),
                                ),
                              ),
                            ],
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'My Clients',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        color: context.textPrimary,
                                        letterSpacing: -0.6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${clients.length}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
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
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.add_rounded, size: 24, color: Colors.white),
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

                  if (widget.isSelectionMode) ...[
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        final contact = await DeviceContactPickerSheet.show(context);
                        if (contact != null && context.mounted) {
                          final newClient = contact.toClient();
                          ref.read(clientProvider.notifier).addClient(newClient);
                          context.pop(newClient);
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.contacts_rounded, color: Color(0xFF2563EB), size: 18),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Select recipient from phone contacts',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF2563EB)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Scrollable Body with Tibsy Pull-to-Refresh ──
            Expanded(
              child: TibsyPullToRefresh(
                padding: EdgeInsets.fromLTRB(20.0, 0, 20.0, isWide ? 32.0 : 120.0),
                onRefresh: () => syncAndRefreshEntireApp(ref),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Client List / Empty State ──
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
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF5722).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.group_add_outlined,
                                      size: 28,
                                      color: Color(0xFFFF5722),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'No clients found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Add clients to organize contacts and create invoices faster.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF64748B),
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  BouncingButton(
                                    onTap: () => _showAddEditClientDialog(),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF5722),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.12),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.add_rounded, size: 18, color: Colors.white),
                                          SizedBox(width: 6),
                                          Text(
                                            'Add Client',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredClients.length,
                        separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                        itemBuilder: (ctx, index) {
                          final client = filteredClients[index];
                          return _buildClientCard(client);
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

  Widget _buildClientCard(Client client) {
    return GestureDetector(
      onTap: () {
        if (widget.isSelectionMode) {
          context.pop(client);
        } else {
          context.push('/client-details', extra: client);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF0F172A),
              child: Text(
                client.name.isNotEmpty ? client.name[0].toUpperCase() : 'C',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HighlightedText(
                    text: client.name,
                    query: _searchQuery,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (client.phone.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 12.5, color: Color(0xFF64748B)),
                        const SizedBox(width: 5),
                        Expanded(
                          child: HighlightedText(
                            text: client.phone,
                            query: _searchQuery,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (client.email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined, size: 12.5, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 5),
                        Expanded(
                          child: HighlightedText(
                            text: client.email,
                            query: _searchQuery,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (client.phone.isEmpty && client.email.isEmpty) ...[
                    const SizedBox(height: 2),
                    const Text(
                      'No contact details',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (client.phone.isNotEmpty) ...[
              GestureDetector(
                onTap: () => ContactService.makeCall(context, client.phone),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECE8),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFF5722).withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.phone_rounded, size: 14, color: Color(0xFFFF5722)),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => ContactService.openWhatsApp(context, client.phone),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.chat_rounded, size: 14, color: Color(0xFF10B981)),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Icon(
              widget.isSelectionMode
                  ? Icons.check_circle_outline_rounded
                  : Icons.arrow_forward_ios_rounded,
              size: widget.isSelectionMode ? 18 : 13,
              color: const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}


