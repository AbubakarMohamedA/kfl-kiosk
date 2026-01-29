import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String brand;
  final double price;
  final String size;
  final String category;
  final String description;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.size,
    required this.category,
    required this.description,
  });

  @override
  List<Object?> get props => [id, name, brand, price, size, category, description];

  Product copyWith({
    String? id,
    String? name,
    String? brand,
    double? price,
    String? size,
    String? category,
    String? description,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      size: size ?? this.size,
      category: category ?? this.category,
      description: description ?? this.description,
    );
  }
}