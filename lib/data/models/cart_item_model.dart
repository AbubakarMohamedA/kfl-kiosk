import 'package:json_annotation/json_annotation.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';
import 'package:kfm_kiosk/data/models/product_model.dart';
import 'package:kfm_kiosk/domain/entities/cart_item.dart';
part 'cart_item_model.g.dart';

@JsonSerializable()
class CartItemModel {
  final ProductModel productModel;
  final int quantity;
  final String status; // ✅ NEW

  const CartItemModel({
    required this.productModel,
    required this.quantity,
    this.status = AppConstants.statusPaid, // ✅ NEW
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) =>
      _$CartItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$CartItemModelToJson(this);

  // ✅ FIXED: Now maps status
  factory CartItemModel.fromEntity(CartItem cartItem) {
    return CartItemModel(
      productModel: ProductModel.fromEntity(cartItem.product),
      quantity: cartItem.quantity,
      status: cartItem.status, // ✅ THIS WAS MISSING
    );
  }

  // ✅ FIXED: Now maps status back
  CartItem toEntity() {
    return CartItem(
      product: productModel.toEntity(),
      quantity: quantity,
      status: status, // ✅ THIS WAS MISSING
    );
  }

  double get subtotal => productModel.price * quantity;

  CartItemModel copyWith({
    ProductModel? productModel,
    int? quantity,
    String? status,
  }) {
    return CartItemModel(
      productModel: productModel ?? this.productModel,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItemModel &&
        other.productModel == productModel &&
        other.quantity == quantity &&
        other.status == status;
  }

  @override
  int get hashCode {
    return productModel.hashCode ^ quantity.hashCode ^ status.hashCode;
  }
}