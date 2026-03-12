import 'package:sss/features/auth/domain/entities/tenant.dart';

abstract class AuthRepository {
  Future<Tenant> login(String username, String password);
  Future<void> logout();
  Future<void> saveSession(Tenant tenant);
  Future<Tenant?> getCurrentTenant();
}
