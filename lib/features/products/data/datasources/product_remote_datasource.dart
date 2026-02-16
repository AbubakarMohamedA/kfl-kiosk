import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kfm_kiosk/core/config/api_config.dart';
import 'package:kfm_kiosk/features/products/data/models/product_model.dart';
import 'package:kfm_kiosk/features/products/domain/entities/product.dart';

abstract class ProductDataSource {
  Future<List<ProductModel>> fetchProducts();
  Future<ProductModel?> getProductById(String id);
}

class ProductRemoteDataSource implements ProductDataSource {
  final http.Client client;

  ProductRemoteDataSource({http.Client? client}) : client = client ?? http.Client();

  @override
  Future<List<ProductModel>> fetchProducts() async {
    final response = await client.get(Uri.parse('${ApiConfig.baseUrl}/products'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ProductModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  @override
  Future<ProductModel?> getProductById(String id) async {
    final response = await client.get(Uri.parse('${ApiConfig.baseUrl}/products/$id'));

    if (response.statusCode == 200) {
      return ProductModel.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load product');
    }
  }
}
