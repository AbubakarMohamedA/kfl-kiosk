import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kfm_kiosk/core/config/api_config.dart';
import 'package:kfm_kiosk/features/products/data/models/product_model.dart';
import 'package:kfm_kiosk/features/products/data/datasources/product_remote_datasource.dart';
import 'package:kfm_kiosk/core/database/daos/app_config_dao.dart';
import 'package:kfm_kiosk/di/injection.dart';

class SapProductDataSource implements ProductDataSource {
  final http.Client client;

  SapProductDataSource({http.Client? client}) : client = client ?? http.Client();

  @override
  Future<List<ProductModel>> fetchProducts({String? tenantId}) async {
    if (ApiConfig.isMockMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return [
        const ProductModel(
          id: 'sap_1',
          name: 'SAP Product 1 (Mock)',
          brand: 'SAP Brand',
          price: 100,
          size: '1kg',
          category: 'Flour',
          description: 'Sample SAP Product',
          imageUrl: 'assets/images/placeholder.png', 
          tenantId: 'enterprise',
        ),
      ];
    }

    String endpoint = ApiConfig.sapProductsEndpoint;
    if (tenantId != null) {
      final appConfigDao = getIt<AppConfigDao>();
      final customUrl = await appConfigDao.getValue('sap_base_url_$tenantId');
      if (customUrl != null && customUrl.isNotEmpty) {
        endpoint = customUrl;
      }
    }

    final uri = Uri.parse(endpoint).replace(
      queryParameters: tenantId != null ? {'tenantId': tenantId} : null,
    );

    try {
      final response = await client.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch SAP products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('SAP Connection Error: $e');
    }
  }

  @override
  Future<ProductModel?> getProductById(String id) async {
    if (ApiConfig.isMockMode) {
       // ... simplified mock logic reused or just return null
       return null; 
    }
    
    final uri = Uri.parse('${ApiConfig.sapProductsEndpoint}/$id');
    try {
      final response = await client.get(uri);
      if (response.statusCode == 200) {
        return ProductModel.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to fetch SAP product: ${response.statusCode}');
      }
    } catch (e) {
       throw Exception('SAP Connection Error: $e');
    }
  }

  @override
  Future<void> addProduct(ProductModel product) async {
    if (ApiConfig.isMockMode) return;

    final uri = Uri.parse(ApiConfig.sapProductsEndpoint);
    try {
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(product.toJson()),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to add SAP product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('SAP Connection Error: $e');
    }
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    if (ApiConfig.isMockMode) return;

    final uri = Uri.parse('${ApiConfig.sapProductsEndpoint}/${product.id}');
    try {
      final response = await client.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(product.toJson()),
      );
      if (response.statusCode != 200) {
         throw Exception('Failed to update SAP product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('SAP Connection Error: $e');
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    if (ApiConfig.isMockMode) return;

    final uri = Uri.parse('${ApiConfig.sapProductsEndpoint}/$id');
    try {
      final response = await client.delete(uri);
      if (response.statusCode != 200) {
         throw Exception('Failed to delete SAP product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('SAP Connection Error: $e');
    }
  }
}
