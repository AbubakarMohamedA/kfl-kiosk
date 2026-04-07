import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sss/core/services/sap_auth_service.dart';
import 'package:sss/core/database/daos/orders_dao.dart';
import 'package:sss/features/orders/data/datasources/sap_invoice_datasource.dart';
import 'package:sss/features/orders/data/models/order_model.dart';
import 'package:sss/features/cart/data/models/cart_item_model.dart';
import 'package:sss/features/products/data/models/product_model.dart';

import 'sap_invoice_datasource_test.mocks.dart';

@GenerateMocks([SapAuthService, http.Client, OrdersDao])
void main() {
  late SapInvoiceDataSource dataSource;
  late MockSapAuthService mockSapAuthService;
  late MockClient mockHttpClient;
  late MockOrdersDao mockOrdersDao;

  setUp(() {
    mockSapAuthService = MockSapAuthService();
    mockHttpClient = MockClient();
    
    // Stub the client getter in SapAuthService
    when(mockSapAuthService.client).thenReturn(mockHttpClient);
    
    mockOrdersDao = MockOrdersDao();
    dataSource = SapInvoiceDataSource(mockSapAuthService, mockOrdersDao);
  });

  group('SapInvoiceDataSource', () {
    final tOrder = OrderModel(
      id: 'ORD001',
      cartItems: [
        CartItemModel(
          productModel: ProductModel(
            id: 'ITM001',
            name: 'Test Product',
            price: 100.0,
            brand: 'Test',
            category: 'Test',
            description: 'Test',
            imageUrl: 'Test',
            size: 'Test',
          ),
          quantity: 2,
        ),
      ],
      total: 200.0,
      phone: '0712345678',
      timestamp: DateTime(2023, 1, 1),
      status: 'Paid',
    );

    test('should send IncomingPayment with Transfer fields and phone as reference', () async {
      // Arrange
      when(mockSapAuthService.isConfigured()).thenAnswer((_) async => true);
      when(mockSapAuthService.getBaseUrl()).thenAnswer((_) async => 'https://mock-sap.com');
      when(mockSapAuthService.getSessionId()).thenAnswer((_) async => 'mock-session');
      when(mockSapAuthService.getRouteId()).thenAnswer((_) async => 'mock-route');
      when(mockSapAuthService.loadCredentials()).thenAnswer((_) async => {
            'walkInCardCode': 'LC00001',
            'currencyCode': 'KES',
            'paymentGlAccount': '160000',
            'taxCode': 'O1',
            'bplId': '1',
          });

      // Stub Invoice creation
      when(mockHttpClient.post(
        Uri.parse('https://mock-sap.com/Invoices'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode({
            'DocEntry': 123,
            'DocTotal': 232.0, // Total with tax
            'BPL_IDAssignedToInvoice': 1, // Add branch detection
          }), 201));

      // Stub Incoming Payment creation
      when(mockHttpClient.post(
        Uri.parse('https://mock-sap.com/IncomingPayments'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode({}), 201));

      // Act
      await dataSource.syncOrderAsInvoice(tOrder);

      // Assert
      // Verify Invoice payload
      final capturedInvoicePayload = verify(mockHttpClient.post(
        Uri.parse('https://mock-sap.com/Invoices'),
        headers: anyNamed('headers'),
        body: captureAnyNamed('body'),
      )).captured.first;

      final Map<String, dynamic> invoicePayload = jsonDecode(capturedInvoicePayload);
      final firstLine = invoicePayload['DocumentLines'][0];
      expect(firstLine['ItemCode'], 'ITM001');
      expect(firstLine['Quantity'], 2);
      expect(firstLine['PriceAfterVAT'], 100.0);
      expect(firstLine['VatGroup'], 'O1');

      // Verify Incoming Payment payload
      final capturedPaymentPayload = verify(mockHttpClient.post(
        Uri.parse('https://mock-sap.com/IncomingPayments'),
        headers: anyNamed('headers'),
        body: captureAnyNamed('body'),
      )).captured.first;

      final Map<String, dynamic> payload = jsonDecode(capturedPaymentPayload);
      
      expect(payload['DocType'], 'rCustomer');
      expect(payload['TransferAccount'], '160000');
      expect(payload['TransferSum'], 232.0);
      expect(payload['TransferReference'], '0712345678');
      expect(payload['TransferDate'], '2023-01-01');
      expect(payload['Remarks'], contains('0712345678'));
      expect(payload['JournalRemarks'], contains('0712345678'));
      expect(payload['CashAccount'], isNull);
      expect(payload['CashSum'], isNull);
      
      final paymentInvoice = payload['PaymentInvoices'][0];
      expect(paymentInvoice['DocEntry'], 123);
      expect(paymentInvoice['SumApplied'], 232.0);
    });
  });
}
