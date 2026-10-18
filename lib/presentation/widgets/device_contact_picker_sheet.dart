import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/device_contact_service.dart';
import '../widgets/highlighted_text.dart';

/// Modal bottom sheet allowing users to pick suggested contacts from their phonebook
/// and search contacts by name saved on their phone.
/// 🔒 100% ON-DEVICE: Contacts are read locally and never uploaded to remote servers.
class DeviceContactPickerSheet extends StatefulWidget {
  final String title;

  const DeviceContactPickerSheet({
    super.key,
    this.title = 'Suggested Contacts',
  });

  /// Static helper to display the sheet and return the selected [DeviceContactInfo].
  static Future<DeviceContactInfo?> show(BuildContext context, {String title = 'Suggested Contacts'}) {
    return showModalBottomSheet<DeviceContactInfo>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DeviceContactPickerSheet(title: title),
    );
  }

  @override
  State<DeviceContactPickerSheet> createState() => _DeviceContactPickerSheetState();
}

class _DeviceContactPickerSheetState extends State<DeviceContactPickerSheet> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _permissionGranted = false;
  bool _isPermanentlyDenied = false;

  List<DeviceContactInfo> _allContacts = [];
  List<DeviceContactInfo> _filteredContacts = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _checkAndLoadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkAndLoadContacts() async {
    setState(() => _isLoading = true);

    final hasPerm = await DeviceContactsService.hasPermission();
    if (hasPerm) {
      final contacts = await DeviceContactsService.loadContacts();
      if (mounted) {
        setState(() {
          _permissionGranted = true;
          _isLoading = false;
          _allContacts = contacts;
          _filteredContacts = contacts;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _permissionGranted = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _requestPermission() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    final granted = await DeviceContactsService.requestPermission();
    if (granted) {
      final contacts = await DeviceContactsService.loadContacts(forceRefresh: true);
      if (mounted) {
        setState(() {
          _permissionGranted = true;
          _isPermanentlyDenied = false;
          _isLoading = false;
          _allContacts = contacts;
          _filteredContacts = contacts;
        });
      }
    } else {
      // Check if permanently denied
      final status = await Permission.contacts.status;
      if (mounted) {
        setState(() {
          _permissionGranted = false;
          _isPermanentlyDenied = status.isPermanentlyDenied;
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filteredContacts = DeviceContactsService.searchContacts(_allContacts, query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final sheetHeight = mediaQuery.size.height * 0.85;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Drag Handle ──
          const SizedBox(height: 12),
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

          // ── Header Bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_permissionGranted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_allContacts.length}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Select or search people saved in your phone',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Privacy Shield Guarantee Banner ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDCFCE7)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: Color(0xFF16A34A)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '100% On-Device & Safe: Contacts are read locally and never uploaded or shared.',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF15803D),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Search Bar (Visible when permission granted) ──
          if (_permissionGranted)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Search by name saved on phone...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                            child: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
            ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // ── Main Body: Loading / Permission Request / Contacts List ──
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF2563EB)),
            SizedBox(height: 14),
            Text(
              'Loading device contacts...',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    if (!_permissionGranted) {
      return _buildPermissionRationaleView();
    }

    if (_filteredContacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_search_rounded, size: 28, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 14),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No contacts matching "$_searchQuery"'
                    : 'No contacts found on this device',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Try searching by another name or phone number.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      itemCount: _filteredContacts.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
      itemBuilder: (ctx, index) {
        final contact = _filteredContacts[index];
        return _buildContactTile(contact);
      },
    );
  }

  Widget _buildContactTile(DeviceContactInfo contact) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context, contact);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            // ── Initials Avatar ──
            CircleAvatar(
              radius: 20,
              backgroundColor: _getAvatarColor(contact.displayName),
              child: Text(
                contact.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // ── Contact Info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HighlightedText(
                    text: contact.displayName,
                    query: _searchQuery,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (contact.primaryPhone.isNotEmpty) ...[
                        const Icon(Icons.phone_rounded, size: 12, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            contact.primaryPhone,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else if (contact.primaryEmail.isNotEmpty) ...[
                        const Icon(Icons.email_outlined, size: 12, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            contact.primaryEmail,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else ...[
                        const Text(
                          'No phone or email listed',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── Select Action Button ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 14, color: Color(0xFF2563EB)),
                  SizedBox(width: 2),
                  Text(
                    'Select',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRationaleView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFFECE8),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFF5722).withValues(alpha: 0.2), width: 2),
            ),
            child: const Icon(Icons.contacts_rounded, color: Color(0xFFFF5722), size: 30),
          ),
          const SizedBox(height: 18),
          const Text(
            'Load Contacts Saved on Phone',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Grant permission to load suggested contacts and quickly search client names saved in your phonebook when creating invoices.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.45),
          ),
          const SizedBox(height: 20),

          // Security Highlights
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              children: [
                _SecurityItem(
                  icon: Icons.lock_outline_rounded,
                  title: '100% On-Device Only',
                  subtitle: 'Contact data stays strictly in your phone and is never sent to external servers.',
                ),
                SizedBox(height: 12),
                _SecurityItem(
                  icon: Icons.visibility_off_outlined,
                  title: 'Read-Only Access',
                  subtitle: 'Inka only reads contact names to autofill invoice recipient details.',
                ),
                SizedBox(height: 12),
                _SecurityItem(
                  icon: Icons.verified_user_outlined,
                  title: 'Selective Saving',
                  subtitle: 'Only contacts you explicitly select are saved as clients in your app.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          if (_isPermanentlyDenied) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 18),
                label: const Text('Open App Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () => openAppSettings(),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                label: const Text('Grant Contact Access', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: _requestPermission,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getAvatarColor(String name) {
    const colors = [
      Color(0xFF2563EB),
      Color(0xFF7C3AED),
      Color(0xFF059669),
      Color(0xFFD97706),
      Color(0xFFE11D48),
      Color(0xFF0891B2),
      Color(0xFF4F46E5),
      Color(0xFF0D9488),
    ];
    final hash = name.codeUnits.fold(0, (sum, code) => sum + code);
    return colors[hash % colors.length];
  }
}

class _SecurityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SecurityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF10B981)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
