import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kfm_kiosk/core/config/api_config.dart';
import 'package:kfm_kiosk/features/auth/domain/entities/tenant.dart';

class AuthRemoteDataSource {
  final http.Client client;

  AuthRemoteDataSource({http.Client? client}) : client = client ?? http.Client();

  Future<Tenant> login(String username, String password) async {
    final response = await client.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Map JSON to Tenant
      return Tenant(
        id: data['id'].toString(),
        name: data['name'],
        businessName: data['businessName'],
        email: data['email'],
        phone: data['phone'],
        status: data['status'] ?? 'Active',
        tier: _parseTier(data['tier']),
        createdDate: DateTime.parse(data['createdDate']),
        lastLogin: data['lastLogin'] != null ? DateTime.parse(data['lastLogin']) : null,
        ordersCount: data['ordersCount'] ?? 0,
        revenue: (data['revenue'] ?? 0).toDouble(),
      );
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Login failed');
    }
  }

  Future<void> logout() async {
    await client.post(Uri.parse('${ApiConfig.baseUrl}/auth/logout'));
  }

  TenantTier _parseTier(String? tier) {
    if (tier?.toLowerCase() == 'premium') return TenantTier.premium;
    return TenantTier.standard;
  }
}
