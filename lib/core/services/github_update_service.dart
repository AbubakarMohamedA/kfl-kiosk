import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../services/platform_service.dart';

/// Service for checking updates from GitHub Releases
/// Perfect for desktop apps and Linux where Firebase isn't available
class GitHubUpdateService {
  static const String DEFAULT_OWNER = 'AbubakarMohamedA';
  static const String DEFAULT_REPO = 'kfl-kiosk';

  final String owner;
  final String repo;
  final String? githubToken; // Optional: for private repos

  GitHubUpdateService({
    this.owner = DEFAULT_OWNER,
    this.repo = DEFAULT_REPO,
    this.githubToken,
  });

  /// Check for latest release from GitHub
  Future<GitHubReleaseInfo?> checkLatestRelease() async {
    return _fetchRelease('latest');
  }

  /// Check for specific release by tag
  Future<GitHubReleaseInfo?> checkReleaseByTag(String tag) async {
    final tagName = tag.startsWith('v') ? tag : 'v$tag';
    return _fetchRelease('tags/$tagName');
  }

  Future<GitHubReleaseInfo?> _fetchRelease(String endpoint) async {
    try {
      final url = Uri.parse(
        'https://api.github.com/repos/$owner/$repo/releases/$endpoint',
      );

      final headers = {
        'Accept': 'application/vnd.github.v3+json',
        if (githubToken != null && githubToken!.isNotEmpty) 'Authorization': 'token $githubToken',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return GitHubReleaseInfo.fromJson(data);
      } else {
        debugPrint('GitHub API error ($endpoint): ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Failed to fetch GitHub release ($endpoint): $e');
      return null;
    }
  }

  /// Get platform-specific download URL from release assets
  String? getPlatformDownloadUrl(GitHubReleaseInfo release, String flavor, String version) {
    if (release.assets.isEmpty) return null;

    final patterns = _getPlatformFilePatterns();
    final flavorLower = flavor.toLowerCase();
    final versionLower = version.toLowerCase();
    
    // Filter out obvious non-installers (checksums, signatures, etc)
    final excludedExtensions = ['.sha256', '.sha1', '.md5', '.sig', '.asc', '.txt'];
    final candidates = release.assets.where((a) {
      final name = a.name.toLowerCase();
      return !excludedExtensions.any((ext) => name.endsWith(ext));
    }).toList();

    if (candidates.isEmpty) return null;

    // 1. Ultra-Precise Match: Flavor + Version + Extension (Best case)
    // Example: kfl_kiosk_dashboard-1.0.32-Setup.exe
    for (final pattern in patterns) {
      if (pattern.startsWith('.')) { // It's an extension
        try {
          final asset = candidates.firstWhere(
            (a) {
              final name = a.name.toLowerCase();
              return name.endsWith(pattern.toLowerCase()) && 
                     name.contains(flavorLower) && 
                     name.contains(versionLower);
            }
          );
          return asset.browserDownloadUrl;
        } catch (_) {}
      }
    }

    // 2. Precise Match: Flavor + Extension (No version in name)
    // Example: kfl_kiosk_dashboard-Setup.exe
    for (final pattern in patterns) {
      if (pattern.startsWith('.')) {
        try {
          final asset = candidates.firstWhere(
            (a) {
              final name = a.name.toLowerCase();
              return name.endsWith(pattern.toLowerCase()) && name.contains(flavorLower);
            }
          );
          return asset.browserDownloadUrl;
        } catch (_) {}
      }
    }

    // 3. Pattern Match: Flavor + Keyword + Version
    // Example: dashboard-linux-x64-1.0.32
    for (final pattern in patterns) {
      try {
        final asset = candidates.firstWhere(
          (a) {
             final name = a.name.toLowerCase();
             return name.contains(pattern.toLowerCase()) && 
                    name.contains(flavorLower) && 
                    name.contains(versionLower);
          }
        );
        return asset.browserDownloadUrl;
      } catch (_) {}
    }

    // 4. Pattern Match: Flavor + Keyword (No version in name)
    for (final pattern in patterns) {
      try {
        final asset = candidates.firstWhere(
          (a) {
             final name = a.name.toLowerCase();
             return name.contains(pattern.toLowerCase()) && name.contains(flavorLower);
          }
        );
        return asset.browserDownloadUrl;
      } catch (_) {}
    }

    // 5. Fallback: Platform Extension/Keyword + Version
    for (final pattern in patterns) {
       try {
        final asset = candidates.firstWhere((a) {
          final name = a.name.toLowerCase();
          final matchesPlatform = pattern.startsWith('.') ? name.endsWith(pattern.toLowerCase()) : name.contains(pattern.toLowerCase());
          return matchesPlatform && name.contains(versionLower);
        });
        return asset.browserDownloadUrl;
      } catch (_) {}
    }

    // 6. Final Fallback: First candidate
    return candidates.first.browserDownloadUrl;
  }

  List<String> _getPlatformFilePatterns() {
    if (PlatformService.isWindows) {
      return ['.exe', '.msi', 'windows', 'win64'];
    } else if (PlatformService.isMacOS) {
      return ['.dmg', '.pkg', 'macos', 'osx'];
    } else if (PlatformService.isLinux) {
      return ['.appimage', '.deb', '.rpm', '.tar.gz', 'linux', 'x86_64'];
    } else if (PlatformService.isAndroid) {
      return ['.apk', 'android'];
    } else if (PlatformService.isIOS) {
      return ['.ipa', 'ios', 'iphone'];
    }
    return [];
  }
}

/// Model for GitHub Release information
class GitHubReleaseInfo {
  final String tagName;
  final String name;
  final String body; // Release notes in Markdown
  final bool prerelease;
  final bool draft;
  final DateTime publishedAt;
  final List<GitHubAsset> assets;
  final String htmlUrl;

  GitHubReleaseInfo({
    required this.tagName,
    required this.name,
    required this.body,
    required this.prerelease,
    required this.draft,
    required this.publishedAt,
    required this.assets,
    required this.htmlUrl,
  });

  /// Clean version string (removes 'v' prefix if present)
  String get version => tagName.startsWith('v') 
      ? tagName.substring(1) 
      : tagName;

  /// Get release notes without markdown (basic cleanup)
  String get cleanReleaseNotes {
    return body
        .replaceAll(RegExp(r'#+\s*'), '') // Remove headers
        .replaceAll(RegExp(r'\*\*'), '') // Remove bold
        .replaceAll(RegExp(r'__'), '') // Remove bold
        .replaceAll(RegExp(r'\*'), '• ') // Convert bullets
        .replaceAll(RegExp(r'```[\s\S]*?```'), '') // Remove code blocks
        .trim();
  }

  factory GitHubReleaseInfo.fromJson(Map<String, dynamic> json) {
    return GitHubReleaseInfo(
      tagName: json['tag_name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      body: json['body'] as String? ?? '',
      prerelease: json['prerelease'] as bool? ?? false,
      draft: json['draft'] as bool? ?? false,
      publishedAt: DateTime.parse(json['published_at'] as String),
      assets: (json['assets'] as List<dynamic>?)
              ?.map((a) => GitHubAsset.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      htmlUrl: json['html_url'] as String? ?? '',
    );
  }
}

/// Model for GitHub Release Asset (downloadable file)
class GitHubAsset {
  final String name;
  final String browserDownloadUrl;
  final int size;
  final String contentType;

  GitHubAsset({
    required this.name,
    required this.browserDownloadUrl,
    required this.size,
    required this.contentType,
  });

  /// Get human-readable file size
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(size / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }

  factory GitHubAsset.fromJson(Map<String, dynamic> json) {
    return GitHubAsset(
      name: json['name'] as String? ?? '',
      browserDownloadUrl: json['browser_download_url'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      contentType: json['content_type'] as String? ?? '',
    );
  }
}
