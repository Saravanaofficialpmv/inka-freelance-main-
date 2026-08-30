import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/product.dart';
import '../../services/firestore_service.dart';

final productSearchQueryProvider = StateProvider<String>((ref) => '');

final productsProvider = StateNotifierProvider<ProductsNotifier, List<Product>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return ProductsNotifier(firestoreService);
});

final filteredProductsProvider = Provider<List<Product>>((ref) {
  final query = ref.watch(productSearchQueryProvider).toLowerCase();
  final products = ref.watch(productsProvider);

  if (query.isEmpty) return products;
  
  return products.where((product) {
    return product.name.toLowerCase().contains(query) ||
           (product.description?.toLowerCase().contains(query) ?? false) ||
           (product.category?.toLowerCase().contains(query) ?? false);
  }).toList();
});

class ProductsNotifier extends StateNotifier<List<Product>> {
  final FirestoreService _firestoreService;

  ProductsNotifier(this._firestoreService) : super([]) {
    _loadProducts();
  }

  late final Box<Product> _productsBox = Hive.box<Product>('products');

  void _loadProducts() {
    state = _productsBox.values.toList();
  }

  void refreshFromLocal() {
    state = _productsBox.values.toList();
  }

  void clear() {
    state = [];
    _productsBox.clear();
  }

  Future<void> addProduct(Product product) async {
    final newProduct = product.id.isEmpty 
        ? product.copyWith(id: DateTime.now().toIso8601String()) 
        : product;
    await _productsBox.put(newProduct.id, newProduct);
    state = _productsBox.values.toList();
    await _firestoreService.saveProduct(newProduct);
  }

  Future<void> updateProduct(Product product) async {
    await _productsBox.put(product.id, product);
    state = _productsBox.values.toList();
    await _firestoreService.saveProduct(product);
  }

  Future<void> deleteProduct(String id) async {
    await _productsBox.delete(id);
    state = _productsBox.values.toList();
    await _firestoreService.deleteProduct(id);
  }
}
