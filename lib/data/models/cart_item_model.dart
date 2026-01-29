import 'package:json_annotation/json_annotation.dart';
import 'package:kfm_kiosk/data/models/product_model.dart';
import 'package:kfm_kiosk/domain/entities/cart_item.dart';

part 'cart_item_model.g.dart';

@JsonSerializable()
class CartItemModel extends CartItem {
  @JsonKey(fromJson: _productFromJson, toJson: _productToJson)
  final ProductModel _product;

  @override
  ProductModel get product => _product;

  const CartItemModel({
    required ProductModel product,
    required super.quantity,
  }) : _product = product,
       super(product: product);

  factory CartItemModel.fromJson(Map<String, dynamic> json) =>
      _$CartItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$CartItemModelToJson(this);

  static ProductModel _productFromJson(Map<String, dynamic> json) =>
      ProductModel.fromJson(json);

  static Map<String, dynamic> _productToJson(ProductModel product) =>
      product.toJson();

  factory CartItemModel.fromEntity(CartItem item) {
    return CartItemModel(
      product: ProductModel.fromEntity(item.product),
      quantity: item.quantity,
    );
  }

  CartItem toEntity() {
    return CartItem(
      product: product.toEntity(),
      quantity: quantity,
    );
  }
}