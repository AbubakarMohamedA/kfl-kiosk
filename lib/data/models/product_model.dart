import 'package:json_annotation/json_annotation.dart';
import 'package:kfm_kiosk/domain/entities/product.dart';

part 'product_model.g.dart';

@JsonSerializable()
class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.brand,
    required super.price,
    required super.size,
    required super.category,
    required super.description,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      name: product.name,
      brand: product.brand,
      price: product.price,
      size: product.size,
      category: product.category,
      description: product.description,
    );
  }

  Product toEntity() {
    return Product(
      id: id,
      name: name,
      brand: brand,
      price: price,
      size: size,
      category: category,
      description: description,
    );
  }
}