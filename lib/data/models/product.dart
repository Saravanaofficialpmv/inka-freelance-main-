import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 5)
class Product extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double defaultPrice;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final String? category;

  Product({
    required this.id,
    required this.name,
    required this.defaultPrice,
    this.description,
    this.category,
  });

  Product copyWith({
    String? id,
    String? name,
    double? defaultPrice,
    String? description,
    String? category,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      defaultPrice: defaultPrice ?? this.defaultPrice,
      description: description ?? this.description,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'defaultPrice': defaultPrice,
      'description': description,
      'category': category,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      defaultPrice: (map['defaultPrice'] as num?)?.toDouble() ?? 0.0,
      description: map['description'],
      category: map['category'],
    );
  }
}
