import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String brand;
  final double price;
  final String size;
  final String category;
  final String description;
  final String imageUrl;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.size,
    required this.category,
    required this.description,
    required this.imageUrl,
  });

  Product copyWith({
    String? id,
    String? name,
    String? brand,
    double? price,
    String? size,
    String? category,
    String? description,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      size: size ?? this.size,
      category: category ?? this.category,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'price': price,
      'size': size,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
    };
  }

  // Create from Firestore map
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      brand: map['brand'] as String,
      price: (map['price'] as num).toDouble(),
      size: map['size'] as String,
      category: map['category'] as String,
      description: map['description'] as String,
      imageUrl: map['imageUrl'] as String,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    brand,
    price,
    size,
    category,
    description,
    imageUrl,
  ];

  @override
  String toString() {
    return 'Product(id: $id, name: $name, brand: $brand, price: $price, size: $size, category: $category, description: $description, imageUrl: $imageUrl)';
  }
}