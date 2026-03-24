import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sss/core/config/api_config.dart';
import 'package:sss/features/products/data/models/product_model.dart';

abstract class ProductDataSource {
  Future<List<ProductModel>> fetchProducts({String? tenantId});
  Future<ProductModel?> getProductById(String id);
  Future<void> addProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(String id);
  void clearCache();
}

class ProductRemoteDataSource implements ProductDataSource {
  final http.Client client;

  ProductRemoteDataSource({http.Client? client}) : client = client ?? http.Client();

  @override
  Future<List<ProductModel>> fetchProducts({String? tenantId}) async {
    final tId = tenantId ?? 'active';
    final response = await client.get(Uri.parse('${ApiConfig.baseUrl}/api/v1/products/$tId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> productsJson = data['products'] ?? [];
      return productsJson.map((json) => ProductModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  @override
  Future<ProductModel?> getProductById(String id) async {
    final response = await client.get(Uri.parse('${ApiConfig.baseUrl}/api/v1/products/detail/$id'));

    if (response.statusCode == 200) {
      return ProductModel.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load product');
    }
  }

  @override
  Future<void> addProduct(ProductModel product) async {
    final response = await client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/products'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add product');
    }
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    final response = await client.put(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/products/${product.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update product');
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    final response = await client.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/products/$id'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete product');
    }
  }

  @override
  void clearCache() {
    // No-op for remote data source
  }
}
