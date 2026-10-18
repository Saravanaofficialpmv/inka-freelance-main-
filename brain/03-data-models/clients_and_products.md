# 03. Data Models — Clients & Products

Clients and Products represent core reusable entities that accelerate invoice composition.

---

## 👥 Client Model (`lib/data/models/client.dart`, TypeId: 0)

```dart
@HiveType(typeId: 0)
class Client extends HiveObject {
  @HiveField(0) final String id;         // Unique Client UUID
  @HiveField(1) final String name;       // Contact or company name
  @HiveField(2) final String phone;      // Phone number
  @HiveField(3) final String email;      // Email address
  @HiveField(4) final String address;    // Physical/billing address
  @HiveField(5) final String? gstNumber; // Client GSTIN or Tax ID
}
```

- **Hive Box**: `clients`
- **Riverpod Provider**: `clientProvider` (`lib/presentation/providers/client_provider.dart`)
- **Firestore Collection**: `/users/{uid}/clients/{clientId}`
- **Features**: Dual-mode rendering (Full CRUD management vs picker selection in invoice creation).

---

## 📦 Product Model (`lib/data/models/product.dart`, TypeId: 5)

```dart
@HiveType(typeId: 5)
class Product extends HiveObject {
  @HiveField(0) final String id;           // Unique Product UUID
  @HiveField(1) final String name;         // Product or service title
  @HiveField(2) final double defaultPrice; // Default unit price
  @HiveField(3) final String? description; // Item description / specifications
  @HiveField(4) final String? category;    // Tag/group (e.g. 'Consulting', 'Design', 'Goods')
}
```

- **Hive Box**: `products`
- **Riverpod Provider**: `productProvider` (`lib/presentation/providers/product_provider.dart`)
- **Firestore Collection**: `/users/{uid}/products/{productId}`
- **Features**: Filterable catalog with search, price pre-filling, and category tagging.
