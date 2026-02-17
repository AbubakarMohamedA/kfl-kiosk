
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm_kiosk/features/auth/domain/entities/tenant.dart';
import 'package:kfm_kiosk/features/auth/domain/entities/tier.dart';
import 'package:kfm_kiosk/features/auth/domain/services/tenant_service.dart';

void main() {
  late TenantService tenantService;

  setUp(() {
    tenantService = TenantService();
    tenantService.resetForTesting();
  });

  group('TenantService Tier Management', () {
    test('should have default tiers initialized', () {
      final tiers = tenantService.getTiers();
      expect(tiers.length, greaterThanOrEqualTo(3));
      expect(tiers.any((t) => t.id == 'standard'), isTrue);
      expect(tiers.any((t) => t.id == 'premium'), isTrue);
      expect(tiers.any((t) => t.id == 'alone'), isTrue);
    });

    test('should add a new tier', () {
      final newTier = Tier(
        id: 'test_tier',
        name: 'Test Tier',
        enabledFeatures: ['orders'],
        allowUpdates: true,
        immuneToBlocking: false,
      );
      tenantService.addTier(newTier);
      expect(tenantService.getTierById('test_tier'), isNotNull);
      expect(tenantService.getTierById('test_tier')?.name, 'Test Tier');
    });

    test('should update an existing tier', () {
      final tier = tenantService.getTierById('standard')!;
      final updatedTier = tier.copyWith(
        name: 'Updated Standard',
        enabledFeatures: ['orders', 'history', 'new_feature'],
      );
      tenantService.updateTier(updatedTier);
      
      final retrievedTier = tenantService.getTierById('standard');
      expect(retrievedTier?.name, 'Updated Standard');
      expect(retrievedTier?.enabledFeatures, contains('new_feature'));
    });

    test('should delete a tier', () {
      // Add a tier first to delete (don't delete defaults to keep other tests safe if they run in parallel, though setUp resets)
      final newTier = Tier(id: 'to_delete', name: 'Delete Me', enabledFeatures: []);
      tenantService.addTier(newTier);
      
      expect(tenantService.getTierById('to_delete'), isNotNull);
      
      tenantService.deleteTier('to_delete');
      expect(tenantService.getTierById('to_delete'), isNull);
    });

    test('should identify Alone tier properties correctly', () {
      final aloneTier = tenantService.getTierById('alone');
      expect(aloneTier, isNotNull);
      expect(aloneTier?.allowUpdates, isFalse);
      expect(aloneTier?.immuneToBlocking, isTrue);
    });
  });

  group('Tenant Access Control', () {
    test('canAccessFeature should respect tier features', () {
      // Create a tenant with 'alone' tier (which has orders, history)
      final tenant = Tenant(
        id: 'test_tenant',
        name: 'Test',
        businessName: 'Test Biz',
        email: 'test@test.com',
        phone: '123',
        status: 'Active',
        tierId: 'alone', // Has ['orders', 'history']
        createdDate: DateTime.now(),
        enabledFeatures: [], // Empty specific features
      );
      tenantService.addTenant(tenant);

      expect(tenantService.canAccessFeature('test_tenant', 'orders'), isTrue);
      expect(tenantService.canAccessFeature('test_tenant', 'history'), isTrue);
      expect(tenantService.canAccessFeature('test_tenant', 'insights'), isFalse); // Not in alone tier
    });

    test('canAccessFeature should respect tenant specific enabled features override', () {
      // Create a tenant with 'alone' tier, but add 'insights' specifically
      final tenant = Tenant(
        id: 'test_tenant_2',
        name: 'Test 2',
        businessName: 'Test Biz 2',
        email: 'test2@test.com',
        phone: '123',
        status: 'Active',
        tierId: 'alone',
        createdDate: DateTime.now(),
        enabledFeatures: ['insights'], 
      );
      tenantService.addTenant(tenant);

      expect(tenantService.canAccessFeature('test_tenant_2', 'orders'), isTrue); // From Tier
      expect(tenantService.canAccessFeature('test_tenant_2', 'insights'), isTrue); // From Tenant override
    });


    test('isTenantImmune should return true for immune tiers', () {
      final tenant = Tenant(
        id: 'immune_tenant_check',
        name: 'Immune Check',
        businessName: 'Immune Biz',
        email: 'immune_check@test.com',
        phone: '123',
        status: 'Active',
        tierId: 'alone', // Immune: true
        createdDate: DateTime.now(),
        enabledFeatures: [],
      );
      tenantService.addTenant(tenant);

      expect(tenantService.isTenantImmune('immune_tenant_check'), isTrue);
    });

    test('isTenantImmune should return false for non-immune tiers', () {
      final tenant = Tenant(
        id: 'non_immune_tenant',
        name: 'Non Immune',
        businessName: 'Non Immune Biz',
        email: 'non_immune@test.com',
        phone: '123',
        status: 'Active',
        tierId: 'standard', // Immune: false
        createdDate: DateTime.now(),
        enabledFeatures: [],
      );
      tenantService.addTenant(tenant);

      expect(tenantService.isTenantImmune('non_immune_tenant'), isFalse);
    });

    test('isTenantImmune should use fallbackTierId if tenant not found', () {
      // Tenant 'missing_tenant' does not exist in service
      // But we provide 'alone' as fallback
      expect(tenantService.isTenantImmune('missing_tenant', fallbackTierId: 'alone'), isTrue);
      
      // Provide 'standard' as fallback
      expect(tenantService.isTenantImmune('missing_tenant', fallbackTierId: 'standard'), isFalse);
    });
  });

  group('Immune to Blocking Logic', () {
    test('canAccessSystem should block normal tenants in maintenance mode', () {
      // Set global maintenance mode
      tenantService.setMaintenanceMode(true);
      
      // Create standard tenant (not immune)
      final tenant = Tenant(
        id: 'standard_tenant',
        name: 'Standard',
        businessName: 'Std Biz',
        email: 'std@test.com',
        phone: '123',
        status: 'Active',
        tierId: 'standard', // Immune: false
        createdDate: DateTime.now(),
        enabledFeatures: [],
      );
      tenantService.addTenant(tenant);

      expect(tenantService.canAccessSystem('standard_tenant'), isFalse);
    });

    test('canAccessSystem should ALLOW immune tenants in maintenance mode', () {
      // Set global maintenance mode
      tenantService.setMaintenanceMode(true);
      
      // Create alone tenant (immune)
      final tenant = Tenant(
        id: 'immune_tenant',
        name: 'Immune',
        businessName: 'Immune Biz',
        email: 'immune@test.com',
        phone: '123',
        status: 'Active',
        tierId: 'alone', // Immune: true
        createdDate: DateTime.now(),
        enabledFeatures: [],
      );
      tenantService.addTenant(tenant);

      expect(tenantService.canAccessSystem('immune_tenant'), isTrue);
    });

    test('canAccessSystem should ALLOW immune tenants even if status is pending/inactive', () {
      // Ensure maintenance mode is off for this test to isolate status check
      tenantService.setMaintenanceMode(false);

      // Create alone tenant with 'Inactive' status
      final tenant = Tenant(
        id: 'inactive_immune_tenant',
        name: 'Inactive Immune',
        businessName: 'Immune Biz',
        email: 'immune2@test.com',
        phone: '123',
        status: 'Inactive',
        tierId: 'alone', // Immune: true
        createdDate: DateTime.now(),
        enabledFeatures: [],
      );
      tenantService.addTenant(tenant);

      // Normal behavior: Inactive -> Blocked
      // Immune behavior: Inactive -> Allowed?
      // Let's check logic. canAccessSystem implementation:
      // if (tenant.status != 'Active' && !isImmune) return false;
      // So if isImmune is true, it skips this return false.
      
      expect(tenantService.canAccessSystem('inactive_immune_tenant'), isTrue);
    });
  });
}
