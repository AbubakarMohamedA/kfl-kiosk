import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sss/core/services/sap_auth_service.dart';

import 'sap_auth_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late SapAuthService service;
  late MockClient mockClient;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'b1_session_id': 'mock-session',
      'server_ip': 'mock-sap.com',
      'sap_company_db': 'SBODemoKE',
      'sap_username': 'manager',
      'sap_password': 'password',
      'sap_last_login_server_ip': 'mock-sap.com',
      'sap_last_login_company_db': 'SBODemoKE',
    });
    mockClient = MockClient();
    service = SapAuthService(client: mockClient);
  });

  group('searchBusinessPartners', () {
    test('should generate correctly encoded filter and trim query without tolower', () async {
      // Arrange
      final query = '  LC00017  ';
      
      when(mockClient.get(
        any,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(jsonEncode({'value': []}), 200));

      // Act
      await service.searchBusinessPartners(query);

      // Assert
      final capturedUri = verify(mockClient.get(
        captureAny,
        headers: anyNamed('headers'),
      )).captured.first as Uri;

      expect(capturedUri.queryParameters['\$filter'], contains('CardCode, \'LC00017\''));
      expect(capturedUri.queryParameters['\$filter'], contains('CardType eq \'cLid\''));
      expect(capturedUri.queryParameters['\$filter'], isNot(contains('tolower')));
    });

    test('should throw exception on non-200 status code', () async {
      // Arrange
      final query = 'test';
      when(mockClient.get(
        any,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(jsonEncode({
            'error': {
              'message': {'value': 'Invalid session'}
            }
          }), 401));

      // Act & Assert
      expect(
        () => service.searchBusinessPartners(query),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Invalid session'))),
      );
    });
  });

  group('ensureSession', () {
    test('should force login even if session exists when force is true', () async {
      // Arrange
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode({
            'SessionId': 'new-session',
            'Version': '900',
          }), 200));

      // Act
      final result = await service.ensureSession(force: true);

      // Assert
      expect(result, isTrue);
      verify(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).called(1);
    });

    test('should NOT force login if session exists and force is false', () async {
      // Act
      final result = await service.ensureSession(force: false);

      // Assert
      expect(result, isTrue);
      verifyNever(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      ));
    });
  });
}
