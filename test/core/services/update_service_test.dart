import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:sss/core/services/update_service.dart';
import 'package:sss/core/models/update_info.dart';
import 'package:sss/features/auth/domain/services/tenant_service.dart';
import 'package:sss/core/configuration/domain/repositories/configuration_repository.dart';
import 'package:sss/core/configuration/domain/entities/app_configuration.dart';
import 'package:sss/core/config/app_role.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

@GenerateMocks([TenantService, ConfigurationRepository])
import 'update_service_test.mocks.dart';

void main() {
  late UpdateService updateService;
  late MockTenantService mockTenantService;
  late MockConfigurationRepository mockConfigRepo;

  setUp(() {
    mockTenantService = MockTenantService();
    mockConfigRepo = MockConfigurationRepository();
    // RoleConfig is simple enough to use directly
    final roleConfig = RoleConfig.forRole(AppRole.kiosk); 
    updateService = UpdateService(mockConfigRepo, roleConfig, mockTenantService);
    
    // Default mocks
    when(mockConfigRepo.getConfiguration()).thenAnswer((_) async => AppConfiguration(tenantId: 'tenant_a'));
    when(mockTenantService.isTenantAllowedUpdates(any)).thenReturn(true);
    
    SharedPreferences.setMockInitialValues({});
    
    TestWidgetsFlutterBinding.ensureInitialized();
    PackageInfo.setMockInitialValues(
      appName: 'test',
      packageName: 'com.test',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: 'sig',
    );
  });

  group('UpdateService - Concurrent Manifest Selection', () {
    test('Should select the highest applicable version from multiple manifests', () async {
      final manifests = <UpdateInfo>[
        // v1.0.1 for Android only
        UpdateInfo(
          latestVersion: '1.0.1',
          currentVersion: '1.0.0',
          requiresUpdate: true,
          isMandatory: false,
          isMaintenanceMode: false,
          allowedPlatforms: ['android'],
        ),
        // v1.0.2 for Windows only
        UpdateInfo(
          latestVersion: '1.0.2',
          currentVersion: '1.0.0',
          requiresUpdate: true,
          isMandatory: false,
          isMaintenanceMode: false,
          allowedPlatforms: ['windows'],
        ),
        // v1.0.3 for Linux only
        UpdateInfo(
          latestVersion: '1.0.3',
          currentVersion: '1.0.0',
          requiresUpdate: true,
          isMandatory: false,
          isMaintenanceMode: false,
          allowedPlatforms: ['linux'],
        ),
      ];

      when(mockTenantService.getLatestUpdateManifests()).thenAnswer((_) async => manifests);

      final result = await updateService.checkForUpdate(force: true);
      
      expect(result, isNotNull);
      expect(result!.latestVersion, equals('1.0.3'));
    });

    test('Should skip manifests that do not apply to current platform', () async {
       final manifests = <UpdateInfo>[
        UpdateInfo(
          latestVersion: '1.0.5',
          currentVersion: '1.0.0',
          requiresUpdate: true,
          isMandatory: false,
          isMaintenanceMode: false,
          allowedPlatforms: ['android', 'ios'],
        ),
      ];

      when(mockTenantService.getLatestUpdateManifests()).thenAnswer((_) async => manifests);

      final result = await updateService.checkForUpdate(force: true);
      expect(result, isNull);
    });

    test('Should favor higher versions over lower versions when both apply', () async {
       final manifests = <UpdateInfo>[
        UpdateInfo(
          latestVersion: '1.0.1',
          currentVersion: '1.0.0',
          requiresUpdate: true,
          isMandatory: false,
          isMaintenanceMode: false,
        ),
        UpdateInfo(
          latestVersion: '1.0.5',
          currentVersion: '1.0.0',
          requiresUpdate: true,
          isMandatory: false,
          isMaintenanceMode: false,
        ),
      ];

      when(mockTenantService.getLatestUpdateManifests()).thenAnswer((_) async => manifests);

      final result = await updateService.checkForUpdate(force: true);
      expect(result!.latestVersion, equals('1.0.5'));
    });
  });
}
