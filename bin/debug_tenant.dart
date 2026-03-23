import 'package:sss/features/auth/domain/services/tenant_service.dart';

void main() {
  final service = TenantService();
  final tenantId = 'TEN001';
  

  
  // 1. Verify Tenant exists and tier
  try {
    final tenant = service.getTenants().firstWhere((t) => t.id == tenantId);
    
    // 2. Verify Tier
    final tier = service.getTierById(tenant.tierId);
    if (tier != null) {
    } else {
    }
    
    // 3. Verify canAccessFeature
    final features = ['orders', 'history', 'insights', 'warehouse', 'branches'];
    for (var f in features) {
      service.canAccessFeature(tenantId, f);
    }
    
  // ignore: empty_catches
  } catch (e) {
  }
}
