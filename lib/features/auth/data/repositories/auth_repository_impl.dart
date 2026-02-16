import 'package:kfm_kiosk/core/config/api_config.dart';
import 'package:kfm_kiosk/features/auth/data/datasources/auth_mock_datasource.dart';
import 'package:kfm_kiosk/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:kfm_kiosk/features/auth/domain/entities/tenant.dart';
import 'package:kfm_kiosk/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthMockDataSource mockDataSource;
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({
    required this.mockDataSource,
    required this.remoteDataSource,
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
    return tenant;
  }

  @override
  Future<void> logout() async {
    _currentTenant = null;
    if (ApiConfig.isMockMode) {
      return mockDataSource.logout();
    } else {
      return remoteDataSource.logout();
    }
  }

  @override
  Future<Tenant?> getCurrentTenant() async {
    return _currentTenant;
  }
  
  // Implement other methods if required by interface
}
