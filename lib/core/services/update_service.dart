import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../../features/auth/domain/services/tenant_service.dart';
import '../models/update_info.dart';
import 'platform_service.dart';
import '../../features/common/presentation/widgets/auto_update_dialog.dart';
import '../configuration/domain/repositories/configuration_repository.dart';
import '../config/app_role.dart';
import 'github_update_service.dart';

/// Security event severity levels
enum SecuritySeverity {
  low,
  medium,
  high,
  critical,
}

/// Security Monitor - Tracks security events
class SecurityMonitor {
  static final SecurityMonitor _instance = SecurityMonitor._internal();
  factory SecurityMonitor() => _instance;
  SecurityMonitor._internal();

  static SecurityMonitor get instance => _instance;

  Future<void> reportSecurityEvent({
    required String eventType,
    required SecuritySeverity severity,
    required Map<String, dynamic> metadata,
  }) async {
    final event = {
      'event_id': const Uuid().v4(),
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'event_type': eventType,
      'severity': severity.name.toUpperCase(),
      'platform': PlatformService.platformName,
      'metadata': metadata,
    };

    debugPrint('🔒 SECURITY EVENT [${severity.name.toUpperCase()}]: $eventType');
    debugPrint('   Metadata: $metadata');

    // Store in secure storage
    try {
      const storage = FlutterSecureStorage();
      final existing = await storage.read(key: 'security_events') ?? '[]';
      final events = List<Map<String, dynamic>>.from(json.decode(existing));
      events.add(event);
      if (events.length > 100) events.removeAt(0);
      await storage.write(key: 'security_events', value: json.encode(events));
    } catch (e) {
      debugPrint('Failed to log security event: $e');
    }
  }
}


/// Update Service - Handles app updates across all 5 platforms
class UpdateService {
  final ConfigurationRepository _configRepo;
  final RoleConfig _roleConfig;
  final TenantService _tenantService;
  
  static const String _keyLastCheckTime = 'update_last_check_time';
  static const String _keyDismissedVersion = 'update_dismissed_version';

  UpdateService(this._configRepo, this._roleConfig, this._tenantService);

  /// Check for updates and show dialog if needed
  Future<void> checkAndPrompt(BuildContext context, {bool force = false}) async {
    final updateInfo = await checkForUpdate(force: force);
    
    if (updateInfo != null && updateInfo.requiresUpdate) {
      if (context.mounted) {
        // We'll use the globalNavigatorKey if context isn't available or just this context
        showDialog(
          context: context,
          barrierDismissible: !updateInfo.isMandatory,
          builder: (ctx) => AutoUpdateDialog(
            updateInfo: updateInfo,
            onSkip: () => Navigator.pop(ctx),
          ),
        );
      }
    }
  }

  /// Core logic to check for updates
  Future<UpdateInfo?> checkForUpdate({bool force = false}) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      UpdateInfo? updateInfo;

      // Check Cloud Manifest first
      updateInfo = await _tenantService.getLatestUpdateManifest();

      if (updateInfo == null) {
        debugPrint('UpdateService: No manifest found, skipping.');
        return null;
      }

      debugPrint('UpdateService: Manifest — latestVersion=${updateInfo.latestVersion}, '
          'requiresUpdate=${updateInfo.requiresUpdate}, isMandatory=${updateInfo.isMandatory}, '
          'allowedTenants=${updateInfo.allowedTenants}, allowedFlavors=${updateInfo.allowedFlavors}');

      // Throttle: skip if checked recently, UNLESS the update is mandatory
      if (!force && !updateInfo.isMandatory && !await _shouldCheck()) {
        debugPrint('UpdateService: Skipping — within 6-hour throttle window.');
        return null;
      }

      // Resolve download URL from GitHub when no explicit URL is stored.
      // isGitHubUpdate is always true for this project, so we always resolve
      // unless the admin already provided a direct updateUrl override.
      if (updateInfo.isGitHubUpdate && (updateInfo.updateUrl == null || updateInfo.updateUrl!.isEmpty)) {
        debugPrint('UpdateService: updateUrl is null — resolving from GitHub...');
        updateInfo = await _checkGitHubRelease(currentVersion, updateInfo);
      }

      if (updateInfo == null) return null;

      // Security check: Downgrade/replay attack
      if (updateInfo.isReplayOrDowngradeAttack(currentVersion)) {
        debugPrint('UpdateService: ⚠️ Blocked — downgrade/replay. '
            'current=$currentVersion, latest=${updateInfo.latestVersion}');
        await SecurityMonitor.instance.reportSecurityEvent(
          eventType: 'downgrade_attack_detected',
          severity: SecuritySeverity.critical,
          metadata: {'current': currentVersion, 'latest': updateInfo.latestVersion},
        );
        return null;
      }

      // Get device identity for filtering
      final config = await _configRepo.getConfiguration();
      final tenantId = config.tenantId ?? '';
      final flavor = _roleConfig.role.name;

      debugPrint('UpdateService: Device — tenantId=$tenantId, flavor=$flavor, version=$currentVersion');

      // Tier gate: alone-tier (allowUpdates: false) never receives updates
      if (!_tenantService.isTenantAllowedUpdates(tenantId)) {
        debugPrint('UpdateService: ⚠️ Update blocked — tenant [$tenantId] tier does not allow updates (alone tier).');
        return null;
      }

      // Granular filtering: Tenant and Flavor
      if (!updateInfo.appliesTo(tenantId, flavor)) {
        debugPrint('UpdateService: ⚠️ Update skipped — not targeted for '
            'tenant [$tenantId] or flavor [$flavor]. '
            'allowedTenants=${updateInfo.allowedTenants}, '
            'allowedFlavors=${updateInfo.allowedFlavors}');
        return null;
      }

      // Save last check time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastCheckTime, DateTime.now().millisecondsSinceEpoch);

      debugPrint('UpdateService: ✅ Update applies — latest=${updateInfo.latestVersion}, '
          'mandatory=${updateInfo.isMandatory}');
      return updateInfo;
    } catch (e) {
      debugPrint('UpdateService: Update check failed: $e');
      return null;
    }
  }

  /// Helper to check GitHub releases
  Future<UpdateInfo> _checkGitHubRelease(String currentVersion, UpdateInfo manifest) async {
    // SECURITY/CONTROL: Only check GitHub if the manifest itself indicates a newer version is available.
    // This allows the Super Admin to "Publish" an update to Firestore first.
    final manifestVersion = manifest.latestVersion;
    final updateRequiredInManifest = _isUpdateRequired(currentVersion, manifestVersion);
    
    if (!updateRequiredInManifest) {
      return manifest.copyWith(requiresUpdate: false);
    }

    final githubService = GitHubUpdateService(
      owner: manifest.githubOwner ?? GitHubUpdateService.DEFAULT_OWNER,
      repo: manifest.githubRepo ?? GitHubUpdateService.DEFAULT_REPO,
      githubToken: manifest.githubToken,
    );
    
    // Fetch the specific release published by the Super Admin
    final release = await githubService.checkReleaseByTag(manifestVersion);
    
    if (release == null) {
      // Fallback to latest if specific tag fetch fails, or just abort
      debugPrint('Specific release $manifestVersion not found on GitHub, falling back to latest check');
      final latestRelease = await githubService.checkLatestRelease();
      if (latestRelease == null) return manifest.copyWith(requiresUpdate: false);
      
      // If latest on GitHub is still less than manifest, respect GitHub (maybe it's not uploaded yet)
      if (!_isUpdateRequired(currentVersion, latestRelease.version)) {
         return manifest.copyWith(requiresUpdate: false);
      }
      
    // Use latest from GitHub
    final flavor = _roleConfig.role.name;
    final githubVersion = latestRelease.version;
    return manifest.copyWith(
      requiresUpdate: true,
      latestVersion: githubVersion,
      updateUrl: githubService.getPlatformDownloadUrl(latestRelease, flavor, githubVersion) ?? latestRelease.htmlUrl,
      releaseNotes: latestRelease.cleanReleaseNotes,
    );
  }
    
    final flavor = _roleConfig.role.name;
    final downloadUrl = githubService.getPlatformDownloadUrl(release, flavor, manifestVersion);
    
    return manifest.copyWith(
      requiresUpdate: true,
      latestVersion: release.version,
      updateUrl: downloadUrl ?? release.htmlUrl,
      releaseNotes: release.cleanReleaseNotes,
      releaseDate: release.publishedAt,
    );
  }

  bool _isUpdateRequired(String current, String latest) {
    try {
      return Version.parse(latest) > Version.parse(current);
    } catch (e) {
      return latest != current;
    }
  }

  Future<bool> _shouldCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(_keyLastCheckTime) ?? 0;
    final lastCheckTime = DateTime.fromMillisecondsSinceEpoch(lastCheck);
    return DateTime.now().difference(lastCheckTime).inHours >= 6;
  }

  /// Download and install update
  Future<void> performUpdate(UpdateInfo updateInfo, {Function(double)? onProgress}) async {
    if (PlatformService.isIOS) {
      // iOS doesn't support programmatic install, just open store
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = 'update_${updateInfo.latestVersion}${_getExt()}';
      final file = File('${tempDir.path}/$fileName');

      final resolvedUrl = updateInfo.updateUrl;
      if (resolvedUrl == null || resolvedUrl.isEmpty) {
        throw Exception('No download URL provided for this update.');
      }

      // Download
      final response = await http.Client().send(http.Request('GET', Uri.parse(resolvedUrl)));
      final contentLength = response.contentLength ?? 0;
      int downloaded = 0;

      final IOSink sink = file.openWrite();
      await response.stream.listen((chunk) {
        sink.add(chunk);
        downloaded += chunk.length;
        if (contentLength > 0) onProgress?.call(downloaded / contentLength);
      }).asFuture();
      await sink.close();

      // Verify Checksum
      if (updateInfo.checksum != null) {
        final bytes = await file.readAsBytes();
        final hash = sha256.convert(bytes).toString();
        if (hash != updateInfo.checksum) {
          throw Exception('Checksum verification failed');
        }
      }

      // Install
      await _install(file.path);
    } catch (e) {
      debugPrint('Update failed: $e');
      rethrow;
    }
  }

  String _getExt() {
    if (PlatformService.isWindows) return '.exe';
    if (PlatformService.isLinux) return '.AppImage';
    if (PlatformService.isMacOS) return '.dmg';
    if (PlatformService.isAndroid) return '.apk';
    return '';
  }

  Future<void> _install(String path) async {
    if (PlatformService.isWindows || PlatformService.isLinux) {
      if (PlatformService.isLinux) {
        await Process.run('chmod', ['+x', path]);
      }
      await Process.start(path, [], mode: ProcessStartMode.detached);
      exit(0);
    } else if (PlatformService.isMacOS) {
      await Process.run('open', [path]);
    } else if (PlatformService.isAndroid) {
      // Requires additional permissions and package like 'open_file'
      debugPrint('Android install triggered for $path');
    }
  }
}
