import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:sss/core/config/api_config.dart';
import 'package:sss/features/products/data/datasources/sap_product_datasource.dart';
import 'package:sss/features/products/data/models/product_model.dart';
import 'dart:convert';

import 'sap_product_datasource_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late SapProductDataSource dataSource;
  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient();
    dataSource = SapProductDataSource(client: mockClient);
    ApiConfig.setFlavor(AppFlavor.prod); // Force prod to test network calls
  });

  group('fetchProducts', () {
    test('returns list of ProductModel when response code is 200', () async {
      final mockResponse = [
        {
          'id': '1',
          'name': 'Test Product',
          'brand': 'Test Brand',
          'price': 100.0,
          'size': '1kg',
          'category': 'Test',
          'description': 'Description',
          'imageUrl': 'url',
          'tenantId': 'tenant_a'
        }
      ];

      when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(jsonEncode(mockResponse), 200));

      final result = await dataSource.fetchProducts(tenantId: 'tenant_a');

      expect(result, isA<List<ProductModel>>());
      expect(result.first.id, '1');
      verify(mockClient.get(any));
    });

    test('throws exception when response code is 404', () async {
      when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response('Not Found', 404));

      expect(() => dataSource.fetchProducts(), throwsException);
    });
  });

  group('addProduct', () {
    test('calls post with correct body', () async {
      final product = ProductModel(
          id: '1',
          name: 'Test',
          brand: 'Brand',
          price: 10.0,
          size: 'S',
          category: 'C',
          description: 'D',
          imageUrl: 'url',
          tenantId: 't1');

      when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response('Created', 201));

      await dataSource.addProduct(product);

      verify(mockClient.post(
        Uri.parse(ApiConfig.sapProductsEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(product.toJson()),
      ));
    });
  });
}
