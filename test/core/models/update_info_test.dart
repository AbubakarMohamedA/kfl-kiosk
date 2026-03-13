import 'package:flutter_test/flutter_test.dart';
import 'package:sss/core/models/update_info.dart';

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
      expect(updateInfo.appliesTo('tenant_a', 'manager', currentPlatform: 'linux'), isTrue);
    });

    test('Should apply to allowed platform', () {
      final updateWithPlatform = updateInfo.copyWith(allowedPlatforms: ['linux', 'windows']);
      expect(updateWithPlatform.appliesTo('tenant_a', 'manager', currentPlatform: 'linux'), isTrue);
      expect(updateWithPlatform.appliesTo('tenant_a', 'manager', currentPlatform: 'windows'), isTrue);
    });

    test('Should skip if platform is not in allowed list', () {
      final updateWithPlatform = updateInfo.copyWith(allowedPlatforms: ['android']);
      expect(updateWithPlatform.appliesTo('tenant_a', 'manager', currentPlatform: 'linux'), isFalse);
    });

    test('Should skip if platform is in excluded list', () {
      final updateWithExclusion = updateInfo.copyWith(excludedPlatforms: ['linux']);
      expect(updateWithExclusion.appliesTo('tenant_a', 'manager', currentPlatform: 'linux'), isFalse);
    });

    test('Should apply if platform matches and is not excluded', () {
      final updateWithFilters = updateInfo.copyWith(
        allowedPlatforms: ['linux', 'windows'],
        excludedPlatforms: ['windows'],
      );
      expect(updateWithFilters.appliesTo('tenant_a', 'manager', currentPlatform: 'linux'), isTrue);
      expect(updateWithFilters.appliesTo('tenant_a', 'manager', currentPlatform: 'windows'), isFalse);
    });

    test('Should skip if tenant is not in allowed list', () {
      expect(updateInfo.appliesTo('tenant_z', 'manager', currentPlatform: 'linux'), isFalse);
    });

    test('Should skip if flavor is not in allowed list', () {
      expect(updateInfo.appliesTo('tenant_a', 'superadmin', currentPlatform: 'linux'), isFalse);
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
      expect(openUpdate.appliesTo('any', 'any', currentPlatform: 'any'), isTrue);
    });
  });
}
