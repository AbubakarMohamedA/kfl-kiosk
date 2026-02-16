import 'package:kfm_kiosk/features/auth/domain/entities/tenant.dart';

abstract class AuthRepository {
  Future<Tenant> login(String username, String password);
  Future<void> logout();
  Future<Tenant?> getCurrentTenant();
}
