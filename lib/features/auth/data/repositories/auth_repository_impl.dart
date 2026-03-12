import 'package:shared_preferences/shared_preferences.dart';
import 'package:sss/core/config/api_config.dart';
import 'package:sss/features/auth/data/datasources/auth_mock_datasource.dart';
import 'package:sss/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:sss/features/auth/domain/entities/tenant.dart';
import 'package:sss/features/auth/domain/repositories/auth_repository.dart';
import 'package:sss/features/auth/domain/services/tenant_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthMockDataSource mockDataSource;
  final AuthRemoteDataSource remoteDataSource;
  final SharedPreferences sharedPreferences;
  final TenantService tenantService;

  static const String _tenantIdKey = 'logged_in_tenant_id';

  AuthRepositoryImpl({
    required this.mockDataSource,
    required this.remoteDataSource,
    required this.sharedPreferences,
    required this.tenantService,
  });

  Tenant? _currentTenant;

  @override
  Future<Tenant> login(String username, String password) async {
    final Tenant tenant;
    if (ApiConfig.isMockMode) {
      tenant = await mockDataSource.login(username, password);
    } else {
      tenant = await remoteDataSource.login(username, password);
    }
    _currentTenant = tenant;
    await sharedPreferences.setString(_tenantIdKey, tenant.id);
    return tenant;
  }

  @override
  Future<void> logout() async {
    _currentTenant = null;
    await sharedPreferences.remove(_tenantIdKey);
    if (ApiConfig.isMockMode) {
      return mockDataSource.logout();
    } else {
      return remoteDataSource.logout();
    }
  }

  @override
  Future<void> saveSession(Tenant tenant) async {
    _currentTenant = tenant;
    await sharedPreferences.setString(_tenantIdKey, tenant.id);
    // Ensure tenant is saved locally for restoration
    await tenantService.addTenant(tenant);
  }

  @override
  Future<Tenant?> getCurrentTenant() async {
    if (_currentTenant != null) return _currentTenant;

    final savedId = sharedPreferences.getString(_tenantIdKey);
    if (savedId != null) {
      // Restore tenant from local database via TenantService
      final tenants = tenantService.getTenants();
      try {
        _currentTenant = tenants.firstWhere((t) => t.id == savedId);
      } catch (e) {
        // If tenant not found in local DB (e.g. wiped), clear session
        await sharedPreferences.remove(_tenantIdKey);
      }
    }

    return _currentTenant;
  }
}
