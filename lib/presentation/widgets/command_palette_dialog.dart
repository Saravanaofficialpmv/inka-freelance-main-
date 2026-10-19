import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/theme_helper.dart';
import '../viewmodels/invoice_viewmodel.dart';
import '../providers/client_provider.dart';
import '../providers/product_provider.dart';
import '../screens/create_invoice_screen.dart';

class CommandPaletteDialog extends ConsumerStatefulWidget {
  const CommandPaletteDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => const CommandPaletteDialog(),
    );
  }

  @override
  ConsumerState<CommandPaletteDialog> createState() => _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends ConsumerState<CommandPaletteDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final invoices = ref.watch(invoiceProvider);
    final clients = ref.watch(clientsProvider);
    final products = ref.watch(productsProvider);

    // Filter items based on query
    final filteredInvoices = query.isEmpty
        ? invoices.take(3).toList()
        : invoices.where((inv) {
            return inv.invoiceNumber.toLowerCase().contains(query) ||
                inv.client.name.toLowerCase().contains(query) ||
                inv.items.any((item) => item.name.toLowerCase().contains(query));
          }).take(4).toList();

    final filteredClients = query.isEmpty
        ? clients.take(3).toList()
        : clients.where((c) {
            return c.name.toLowerCase().contains(query) ||
                c.email.toLowerCase().contains(query) ||
                c.phone.toLowerCase().contains(query);
          }).take(3).toList();

    final filteredProducts = query.isEmpty
        ? products.take(2).toList()
        : products.where((p) {
            return p.name.toLowerCase().contains(query) ||
                (p.description ?? '').toLowerCase().contains(query);
          }).take(3).toList();

    // Default quick actions
    final quickActions = <_PaletteAction>[
      _PaletteAction(
        title: 'Create Invoice',
        subtitle: 'New professional invoice or estimate',
        icon: Icons.add_rounded,
        onTap: () {
          Navigator.of(context).pop();
          CreateInvoiceScreen.showAsBottomSheet(context);
        },
      ),
      _PaletteAction(
        title: 'View Invoices',
        subtitle: 'Browse all sent, pending & paid invoices',
        icon: Icons.receipt_long_outlined,
        onTap: () {
          Navigator.of(context).pop();
          context.go('/history');
        },
      ),
      _PaletteAction(
        title: 'Manage Clients',
        subtitle: 'View client directory and contact info',
        icon: Icons.people_outline_rounded,
        onTap: () {
          Navigator.of(context).pop();
          context.go('/clients');
        },
      ),
      _PaletteAction(
        title: 'Products & Services Catalog',
        subtitle: 'Manage saved rate items and inventory',
        icon: Icons.inventory_2_outlined,
        onTap: () {
          Navigator.of(context).pop();
          context.go('/products');
        },
      ),
      _PaletteAction(
        title: 'Financial Expenses & Reports',
        subtitle: 'Track profit, loss, and business expenses',
        icon: Icons.bar_chart_rounded,
        onTap: () {
          Navigator.of(context).pop();
          context.go('/expenses');
        },
      ),
      _PaletteAction(
        title: 'Settings & Workspace',
        subtitle: 'Business profile, templates, signatures',
        icon: Icons.settings_outlined,
        onTap: () {
          Navigator.of(context).pop();
          context.go('/profile');
        },
      ),
    ].where((act) {
      if (query.isEmpty) return true;
      return act.title.toLowerCase().contains(query) ||
          act.subtitle.toLowerCase().contains(query);
    }).toList();

    // Build unified actionable list
    final List<Widget> results = [];

    // Quick Actions
    if (quickActions.isNotEmpty) {
      results.add(_buildSectionHeader('Quick Actions'));
      for (final action in quickActions) {
        results.add(
          _PaletteTile(
            icon: action.icon,
            iconBg: AppColors.iconBg,
            iconColor: AppColors.primary,
            title: action.title,
            subtitle: action.subtitle,
            onTap: action.onTap,
          ),
        );
      }
    }

    // Invoices
    if (filteredInvoices.isNotEmpty) {
      results.add(_buildSectionHeader('Invoices'));
      for (final inv in filteredInvoices) {
        results.add(
          _PaletteTile(
            icon: Icons.receipt_rounded,
            iconBg: inv.isPaid ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
            iconColor: inv.isPaid ? AppColors.success : const Color(0xFFF59E0B),
            title: '${inv.invoiceNumber} • ${inv.client.name}',
            subtitle: '${inv.isPaid ? "Paid" : "Pending"} • \$${inv.total.toStringAsFixed(2)}',
            trailingBadge: inv.isPaid ? 'PAID' : 'PENDING',
            badgeColor: inv.isPaid ? AppColors.success : const Color(0xFFF59E0B),
            onTap: () {
              Navigator.of(context).pop();
              context.go('/history');
            },
          ),
        );
      }
    }

    // Clients
    if (filteredClients.isNotEmpty) {
      results.add(_buildSectionHeader('Clients'));
      for (final client in filteredClients) {
        results.add(
          _PaletteTile(
            icon: Icons.person_rounded,
            iconBg: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF2563EB),
            title: client.name,
            subtitle: client.email.isNotEmpty ? client.email : (client.phone.isNotEmpty ? client.phone : 'Client'),
            onTap: () {
              Navigator.of(context).pop();
              context.go('/clients');
            },
          ),
        );
      }
    }

    // Products
    if (filteredProducts.isNotEmpty) {
      results.add(_buildSectionHeader('Products & Services'));
      for (final prod in filteredProducts) {
        results.add(
          _PaletteTile(
            icon: Icons.sell_rounded,
            iconBg: const Color(0xFFF3E8FF),
            iconColor: const Color(0xFF9333EA),
            title: prod.name,
            subtitle: '\$${prod.defaultPrice.toStringAsFixed(2)} ${prod.category != null ? "• ${prod.category}" : ""}',
            onTap: () {
              Navigator.of(context).pop();
              context.go('/products');
            },
          ),
        );
      }
    }

    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 80, left: 24, right: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 520),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 22, color: AppColors.primary),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        autofocus: true,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search invoices, clients, products, or commands...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF94A3B8),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                        splashRadius: 16,
                        onPressed: () {
                          _searchController.clear();
                        },
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Text(
                        'ESC',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Results List
              Flexible(
                child: results.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded, size: 40, color: context.textMuted),
                            const SizedBox(height: 10),
                            Text(
                              'No matching results found',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try searching with a different keyword or client name.',
                              style: TextStyle(fontSize: 12.5, color: context.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: results,
                      ),
              ),

              // Footer helper
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.keyboard_outlined, size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Navigate with click or arrow keys • Press Enter to select • Esc to close',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFF94A3B8),
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _PaletteAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  _PaletteAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

class _PaletteTile extends StatefulWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? trailingBadge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _PaletteTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailingBadge,
    this.badgeColor,
    required this.onTap,
  });

  @override
  State<_PaletteTile> createState() => _PaletteTileState();
}

class _PaletteTileState extends State<_PaletteTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFFF1F5F9) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon, size: 16, color: widget.iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (widget.trailingBadge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: (widget.badgeColor ?? AppColors.primary).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.trailingBadge!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: widget.badgeColor ?? AppColors.primary,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFCBD5E1)),
            ],
          ),
        ),
      ),
    );
  }
}
