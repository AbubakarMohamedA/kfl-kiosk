import 'package:sss/features/auth/domain/services/tenant_service.dart';

void main() {
  final service = TenantService();
  final tenantId = 'TEN001';
  

  
  // 1. Verify Tenant exists and tier
  try {
    final tenant = service.getTenants().firstWhere((t) => t.id == tenantId);
    print('Tenant Found: ${tenant.businessName}');
    print('Tenant Tier ID: ${tenant.tierId}');
    print('Tenant Enabled Features: ${tenant.enabledFeatures}');
    
    // 2. Verify Tier
    final tier = service.getTierById(tenant.tierId);
    if (tier != null) {
      print('Tier Found: ${tier.name}');
      print('Tier Enabled Features: ${tier.enabledFeatures}');
    } else {
      print('ERROR: Tier not found!');
    }
    
    // 3. Verify canAccessFeature
    final features = ['orders', 'history', 'insights', 'warehouse', 'branches'];
    for (var f in features) {
      final canAccess = service.canAccessFeature(tenantId, f);
      print('canAccessFeature($tenantId, $f) = $canAccess');
    }
    
  } catch (e) {
    print('ERROR: Tenant not found! $e');
  }
}
