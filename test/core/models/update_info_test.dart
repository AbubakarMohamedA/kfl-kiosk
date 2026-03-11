import 'package:flutter_test/flutter_test.dart';
import 'package:kfm_kiosk/core/models/update_info.dart';

void main() {
  group('UpdateInfo Filtering Tests', () {
    final updateInfo = UpdateInfo(
      requiresUpdate: true,
      isMandatory: false,
      isMaintenanceMode: false,
      updateUrl: 'http://example.com',
      currentVersion: '1.0.0',
      latestVersion: '1.1.0',
      allowedTenants: ['tenant_a', 'tenant_b'],
      allowedFlavors: ['manager', 'staff'],
      excludedTenants: ['tenant_c'],
      excludedFlavors: ['kiosk'],
    );

    test('Should apply to allowed tenant and flavor', () {
      expect(updateInfo.appliesTo('tenant_a', 'manager'), isTrue);
    });

    test('Should skip if tenant is not in allowed list', () {
      expect(updateInfo.appliesTo('tenant_z', 'manager'), isFalse);
    });

    test('Should skip if flavor is not in allowed list', () {
      expect(updateInfo.appliesTo('tenant_a', 'superadmin'), isFalse);
    });

    test('Should skip if tenant is in excluded list', () {
      expect(updateInfo.appliesTo('tenant_c', 'manager'), isFalse);
    });

    test('Should skip if flavor is in excluded list', () {
      final updateInfoWithExclusion = updateInfo.copyWith(
        allowedFlavors: [], // Clear allowed to test exclusion independently
      );
      expect(updateInfoWithExclusion.appliesTo('tenant_a', 'kiosk'), isFalse);
    });

    test('Should apply if no restrictions exist', () {
      final openUpdate = UpdateInfo(
        requiresUpdate: true,
        isMandatory: false,
        isMaintenanceMode: false,
        updateUrl: 'http://example.com',
        currentVersion: '1.0.0',
        latestVersion: '1.1.0',
      );
      expect(openUpdate.appliesTo('any', 'any'), isTrue);
    });
  });
}
