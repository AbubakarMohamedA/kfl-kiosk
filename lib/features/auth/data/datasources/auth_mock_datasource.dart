import 'package:kfm_kiosk/features/auth/domain/entities/tenant.dart';
import 'package:kfm_kiosk/features/auth/domain/services/tenant_service.dart';

class AuthMockDataSource {
  final TenantService _tenantService = TenantService();

  Future<Tenant> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    final tenant = _tenantService.login(email, password);
    
    if (tenant != null) {
      return tenant;
    } else {
      throw Exception('Invalid credentials');
    }
  }

  Future<void> logout() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
