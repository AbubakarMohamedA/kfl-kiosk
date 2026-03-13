import 'dart:io';
import 'package:version/version.dart';
import 'package:flutter/foundation.dart';

/// Update strategy enum
enum UpdateStrategy {
  silent,
  prompted,
  forced,
}

/// Update status for tracking
enum UpdateStatus {
  idle,
  checking,
  downloading,
  downloaded,
  installing,
  installed,
  failed,
  queued,
}

/// Model for update information
class UpdateInfo {
  final bool requiresUpdate;
  final bool isMandatory;
  final bool isMaintenanceMode;
  final String? updateUrl;
  final String currentVersion;
  final String latestVersion;
  final String maintenanceMessage;
  final String releaseNotes;
  final DateTime? releaseDate;
  final String? downloadedFilePath;
  final UpdateStrategy strategy;
  final String? checksum;
  final int? sizeBytes;
  final String? deltaUpdateUrl;
  final String? deltaChecksum;
  final String? minimumSupportedVersion;

  // Granular control fields
  final List<String> allowedTenants;
  final List<String> allowedFlavors;
  final List<String> excludedTenants;
  final List<String> excludedFlavors;
  final List<String> allowedPlatforms;
  final List<String> excludedPlatforms;

  // GitHub Release fields
  final String? githubOwner;
  final String? githubRepo;
  final String? githubToken;

  UpdateInfo({
    required this.requiresUpdate,
    required this.isMandatory,
    required this.isMaintenanceMode,
    this.updateUrl,
    required this.currentVersion,
    required this.latestVersion,
    this.maintenanceMessage = '',
    this.releaseNotes = '',
    this.releaseDate,
    this.downloadedFilePath,
    this.strategy = UpdateStrategy.prompted,
    this.checksum,
    this.sizeBytes,
    this.deltaUpdateUrl,
    this.deltaChecksum,
    this.minimumSupportedVersion,
    this.allowedTenants = const [],
    this.allowedFlavors = const [],
    this.excludedTenants = const [],
    this.excludedFlavors = const [],
    this.allowedPlatforms = const [],
    this.excludedPlatforms = const [],
    this.githubOwner,
    this.githubRepo,
    this.githubToken,
  });

  /// Whether this update should be fetched from GitHub
  bool get isGitHubUpdate => true; // Hardcoded for this project as requested

  bool get hasReleaseNotes => releaseNotes.isNotEmpty;
  bool get isDownloaded =>
      downloadedFilePath != null && File(downloadedFilePath!).existsSync();
  bool get hasDeltaUpdate =>
      deltaUpdateUrl != null && deltaUpdateUrl!.isNotEmpty;

  /// Check if this update is a replay or downgrade attack
  bool isReplayOrDowngradeAttack(String currentVersion) {
    try {
      // Prevent downgrades
      if (Version.parse(latestVersion) < Version.parse(currentVersion)) {
        debugPrint('⚠️ SECURITY: Downgrade attack detected');
        return true;
      }

      // Prevent updates older than security window (90 days)
      if (releaseDate != null) {
        final age = DateTime.now().difference(releaseDate!);
        if (age > const Duration(days: 90)) {
          debugPrint('⚠️ SECURITY: Update older than 90 days');
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error checking replay/downgrade: $e');
      return true; // Fail secure
    }
  }

  /// Check if this update applies to the current tenant and flavor.
  /// All comparisons are case-insensitive to prevent mismatches between
  /// Firestore-stored values (e.g. "superadmin") and runtime enum names
  /// (e.g. AppRole.superAdmin.name → "superAdmin").
  bool appliesTo(String currentTenantId, String currentFlavor, {String? currentPlatform}) {
    final tenantLower = currentTenantId.toLowerCase();
    final flavorLower = currentFlavor.toLowerCase();
    final platformLower = currentPlatform?.toLowerCase();

    // If allowed lists are provided, current must be in them
    if (allowedTenants.isNotEmpty &&
        !allowedTenants.any((t) => t.toLowerCase() == tenantLower)) {
      return false;
    }
    if (allowedFlavors.isNotEmpty &&
        !allowedFlavors.any((f) => f.toLowerCase() == flavorLower)) {
      return false;
    }
    if (currentPlatform != null &&
        allowedPlatforms.isNotEmpty &&
        !allowedPlatforms.any((p) => p.toLowerCase() == platformLower)) {
      return false;
    }

    // If excluded lists are provided, current must NOT be in them
    if (excludedTenants.any((t) => t.toLowerCase() == tenantLower)) {
      return false;
    }
    if (excludedFlavors.any((f) => f.toLowerCase() == flavorLower)) {
      return false;
    }
    if (currentPlatform != null &&
        excludedPlatforms.any((p) => p.toLowerCase() == platformLower)) {
      return false;
    }

    return true;
  }

  UpdateInfo copyWith({
    bool? requiresUpdate,
    bool? isMandatory,
    bool? isMaintenanceMode,
    String? updateUrl,
    String? currentVersion,
    String? latestVersion,
    String? maintenanceMessage,
    String? releaseNotes,
    DateTime? releaseDate,
    String? downloadedFilePath,
    UpdateStrategy? strategy,
    String? checksum,
    int? sizeBytes,
    String? deltaUpdateUrl,
    String? deltaChecksum,
    String? minimumSupportedVersion,
    List<String>? allowedTenants,
    List<String>? allowedFlavors,
    List<String>? excludedTenants,
    List<String>? excludedFlavors,
    List<String>? allowedPlatforms,
    List<String>? excludedPlatforms,
    String? githubOwner,
    String? githubRepo,
    String? githubToken,
  }) {
    return UpdateInfo(
      requiresUpdate: requiresUpdate ?? this.requiresUpdate,
      isMandatory: isMandatory ?? this.isMandatory,
      isMaintenanceMode: isMaintenanceMode ?? this.isMaintenanceMode,
      updateUrl: updateUrl ?? this.updateUrl,
      currentVersion: currentVersion ?? this.currentVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      maintenanceMessage: maintenanceMessage ?? this.maintenanceMessage,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      releaseDate: releaseDate ?? this.releaseDate,
      downloadedFilePath: downloadedFilePath ?? this.downloadedFilePath,
      strategy: strategy ?? this.strategy,
      checksum: checksum ?? this.checksum,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      deltaUpdateUrl: deltaUpdateUrl ?? this.deltaUpdateUrl,
      deltaChecksum: deltaChecksum ?? this.deltaChecksum,
      minimumSupportedVersion:
          minimumSupportedVersion ?? this.minimumSupportedVersion,
      allowedTenants: allowedTenants ?? this.allowedTenants,
      allowedFlavors: allowedFlavors ?? this.allowedFlavors,
      excludedTenants: excludedTenants ?? this.excludedTenants,
      excludedFlavors: excludedFlavors ?? this.excludedFlavors,
      allowedPlatforms: allowedPlatforms ?? this.allowedPlatforms,
      excludedPlatforms: excludedPlatforms ?? this.excludedPlatforms,
      githubOwner: githubOwner ?? this.githubOwner,
      githubRepo: githubRepo ?? this.githubRepo,
      githubToken: githubToken ?? this.githubToken,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requiresUpdate': requiresUpdate,
      'isMandatory': isMandatory,
      'isMaintenanceMode': isMaintenanceMode,
      'updateUrl': updateUrl,
      'currentVersion': currentVersion,
      'latestVersion': latestVersion,
      'maintenanceMessage': maintenanceMessage,
      'releaseNotes': releaseNotes,
      'releaseDate': releaseDate?.toIso8601String(),
      'downloadedFilePath': downloadedFilePath,
      'strategy': strategy.name,
      'checksum': checksum,
      'sizeBytes': sizeBytes,
      'deltaUpdateUrl': deltaUpdateUrl,
      'deltaChecksum': deltaChecksum,
      'minimumSupportedVersion': minimumSupportedVersion,
      'allowedTenants': allowedTenants,
      'allowedFlavors': allowedFlavors,
      'excludedTenants': excludedTenants,
      'excludedFlavors': excludedFlavors,
      'allowedPlatforms': allowedPlatforms,
      'excludedPlatforms': excludedPlatforms,
      'githubOwner': githubOwner,
      'githubRepo': githubRepo,
      'githubToken': githubToken,
    };
  }

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      requiresUpdate: json['requiresUpdate'] ?? false,
      isMandatory: json['isMandatory'] ?? false,
      isMaintenanceMode: json['isMaintenanceMode'] ?? false,
      updateUrl: json['updateUrl'],
      currentVersion: json['currentVersion'] ?? '',
      latestVersion: json['latestVersion'] ?? '',
      maintenanceMessage: json['maintenanceMessage'] ?? '',
      releaseNotes: json['releaseNotes'] ?? '',
      releaseDate: json['releaseDate'] != null
          ? DateTime.parse(json['releaseDate'])
          : null,
      downloadedFilePath: json['downloadedFilePath'],
      strategy: UpdateStrategy.values.firstWhere(
        (e) => e.name == json['strategy'],
        orElse: () => UpdateStrategy.prompted,
      ),
      checksum: json['checksum'],
      sizeBytes: json['sizeBytes'],
      deltaUpdateUrl: json['deltaUpdateUrl'],
      deltaChecksum: json['deltaChecksum'],
      minimumSupportedVersion: json['minimumSupportedVersion'],
      allowedTenants: List<String>.from(json['allowedTenants'] ?? []),
      allowedFlavors: List<String>.from(json['allowedFlavors'] ?? []),
      excludedTenants: List<String>.from(json['excludedTenants'] ?? []),
      excludedFlavors: List<String>.from(json['excludedFlavors'] ?? []),
      allowedPlatforms: List<String>.from(json['allowedPlatforms'] ?? []),
      excludedPlatforms: List<String>.from(json['excludedPlatforms'] ?? []),
      githubOwner: json['githubOwner'],
      githubRepo: json['githubRepo'],
      githubToken: json['githubToken'],
    );
  }
}
