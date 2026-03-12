import 'package:json_annotation/json_annotation.dart';
import 'package:sss/features/products/domain/entities/product.dart';

part 'product_model.g.dart';

@JsonSerializable()
class ProductModel {
  final String id;
  final String name;
  final String brand;
  final double price;
  final String size;
  final String category;
  final String description;
  final String imageUrl;
  final String? tenantId;
  final String? branchId;

  const ProductModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.size,
    required this.category,
    required this.description,
    required this.imageUrl,
    this.tenantId,
    this.branchId,
  });

  // Factory constructor for creating a ProductModel from JSON
  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  // Method for converting ProductModel to JSON
  Map<String, dynamic> toJson() => _$ProductModelToJson(this);

  // Convert ProductModel to Product Entity
  Product toEntity() {
    return Product(
      id: id,
      name: name,
      brand: brand,
      price: price,
      size: size,
      category: category,
      description: description,
      imageUrl: imageUrl,
      tenantId: tenantId,
      branchId: branchId,
    );
  }

  // Create ProductModel from Product Entity
  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      name: product.name,
      brand: product.brand,
      price: product.price,
      size: product.size,
      category: product.category,
      description: product.description,
      imageUrl: product.imageUrl,
      tenantId: product.tenantId,
      branchId: product.branchId,
    );
  }

  // CopyWith method for creating a modified copy
  ProductModel copyWith({
    String? id,
    String? name,
    String? brand,
    double? price,
    String? size,
    String? category,
    String? description,
    String? imageUrl,
    String? tenantId,
    String? branchId,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      size: size ?? this.size,
      category: category ?? this.category,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
    );
  }

  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, brand: $brand, price: $price, size: $size, category: $category, description: $description, imageUrl: $imageUrl, tenantId: $tenantId, branchId: $branchId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProductModel &&
        other.id == id &&
        other.name == name &&
        other.brand == brand &&
        other.price == price &&
        other.size == size &&
        other.category == category &&
        other.description == description &&
        other.imageUrl == imageUrl &&
        other.tenantId == tenantId &&
        other.branchId == branchId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        brand.hashCode ^
        price.hashCode ^
        size.hashCode ^
        category.hashCode ^
        description.hashCode ^
        imageUrl.hashCode ^
        tenantId.hashCode ^
        branchId.hashCode;
  }
}