import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/product.dart';
import '../providers/product_provider.dart';
import '../providers/profile_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/currency_tax_service.dart';
import '../widgets/tibsy_refresh_icon.dart';
import '../widgets/app_search_bar.dart';
import '../../core/utils/validators.dart';
import '../../core/theme/theme_helper.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  final bool isSelectionMode;
  
  const ProductsScreen({super.key, this.isSelectionMode = false});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(filteredProductsProvider);
    final profile = ref.watch(profileProvider);
    final currencyFormat = CurrencyTaxService.getCurrencyFormatter(
      currencyCode: profile.currency.isNotEmpty ? profile.currency : 'USD',
      decimalDigits: 0,
    );

    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final showBackButton = widget.isSelectionMode || (context.canPop() && !isWide);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: EdgeInsets.fromLTRB(
                isWide ? 24.0 : 20.0,
                isWide ? 20.0 : 12.0,
                isWide ? 24.0 : 20.0,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (showBackButton) ...[
                              GestureDetector(
                                onTap: () => context.canPop() ? context.pop() : context.go('/dashboard'),
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
                            Flexible(
                              child: Text(
                                AppLocalizations.of(context)?.translate('product_catalog') ?? 'Product Catalog',
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
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showProductDialog(context, null),
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
                          child: const Icon(Icons.add_rounded, size: 24, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppSearchBar(
                    controller: _searchController,
                    hintText: AppLocalizations.of(context)?.translate('search') ?? 'Search items & services...',
                    onChanged: (value) => ref.read(productSearchQueryProvider.notifier).state = value,
                    onClear: () {
                      _searchController.clear();
                      ref.read(productSearchQueryProvider.notifier).state = '';
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Section label
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 24.0 : 20.0),
              child: Row(
                children: const [
                  Text(
                    'SERVICES & PRODUCTS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── Products List ──
            Expanded(
              child: TibsyPullToRefresh(
                padding: EdgeInsets.fromLTRB(isWide ? 24 : 20, 0, isWide ? 24 : 20, isWide ? 32 : 100),
                onRefresh: () => syncAndRefreshEntireApp(ref),
                child: products.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.inventory_2_outlined, size: 56, color: Color(0xFFCBD5E1)),
                              SizedBox(height: 14),
                              Text('No products found', style: TextStyle(color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: products.map((product) {
                          return _ProductListItem(
                            product: product,
                            currencyFormat: currencyFormat,
                            isSelectionMode: widget.isSelectionMode,
                            onEdit: () => _showProductDialog(context, product),
                            onDelete: () => _deleteProduct(context, product.id),
                            onTap: () {
                              if (widget.isSelectionMode) {
                                context.pop(product);
                              } else {
                                _showProductDialog(context, product);
                              }
                            },
                          );
                        }).toList(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteProduct(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        title: const Text('Delete Product?', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to remove this product from your catalog?', style: TextStyle(color: Color(0xFF64748B))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B)))),
          TextButton(
            onPressed: () {
              ref.read(productsProvider.notifier).deleteProduct(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showProductDialog(BuildContext context, Product? product) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(text: product?.defaultPrice.toString() ?? '');
    final descController = TextEditingController(text: product?.description ?? '');
    final categoryController = TextEditingController(text: product?.category ?? '');

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product == null ? 'Add Product' : 'Update Product',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B))),
                ],
              ),
              const SizedBox(height: 20),
              _BuildField(controller: nameController, label: 'Product / Service Name', icon: Icons.shopping_bag_outlined),
              const SizedBox(height: 14),
              _BuildField(controller: priceController, label: 'Default Price', icon: Icons.attach_money, keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              _BuildField(controller: categoryController, label: 'Category', icon: Icons.category_outlined),
              const SizedBox(height: 14),
              _BuildField(controller: descController, label: 'Description', icon: Icons.description_outlined, maxLines: 2),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product / Service name is required')));
                      return;
                    }
                    final priceErr = AppValidators.validatePrice(priceController.text, 'Price');
                    if (priceErr != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(priceErr)));
                      return;
                    }
                    final newProduct = Product(
                      id: product?.id ?? '',
                      name: name,
                      defaultPrice: double.parse(priceController.text.trim()),
                      description: descController.text.trim(),
                      category: categoryController.text.trim(),
                    );
                    if (product == null) {
                      await ref.read(productsProvider.notifier).addProduct(newProduct);
                    } else {
                      await ref.read(productsProvider.notifier).updateProduct(newProduct);
                    }
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product catalog updated')));
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: const Text('Save Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductListItem extends StatelessWidget {
  final Product product;
  final NumberFormat currencyFormat;
  final bool isSelectionMode;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _ProductListItem({
    required this.product,
    required this.currencyFormat,
    required this.isSelectionMode,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: context.isDarkMode ? const Color(0xFF332018) : const Color(0xFFFFECE8),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFF5722).withValues(alpha: 0.25)),
              ),
              child: const Center(child: Icon(Icons.inventory_2_outlined, color: Color(0xFFFF5722), size: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.category ?? 'General Service',
                    style: TextStyle(color: context.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(product.defaultPrice),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFFF5722)),
                ),
                if (!isSelectionMode)
                  Row(
                    children: [
                      IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_note, color: Color(0xFF64748B), size: 22)),
                      IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BuildField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final TextInputType keyboardType;

  const _BuildField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 19, color: const Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
