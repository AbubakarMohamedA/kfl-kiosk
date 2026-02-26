import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kfm_kiosk/core/config/api_config.dart';
import 'package:kfm_kiosk/core/configuration/domain/repositories/configuration_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:kfm_kiosk/core/database/daos/tenant_config_dao.dart';
import 'package:kfm_kiosk/core/database/app_database.dart' as drift_db;
import 'package:drift/drift.dart' as drift;
import 'package:kfm_kiosk/di/injection.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class SyncResult {
  final bool success;
  final String message;
  final String? troubleshootingStep;

  SyncResult({required this.success, required this.message, this.troubleshootingStep});
}

class SyncService {
  final ConfigurationRepository _configRepo;
  Timer? _syncTimer;

  SyncService(this._configRepo);

  void startAutoSync(String ip) {
    stopAutoSync();
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await connectAndSync(ip);
      
      // NEW: Send heartbeat
      try {
        final prefs = await SharedPreferences.getInstance();
        final terminalName = prefs.getString('terminal_name') ?? 'Unknown Terminal';
        await http.post(
          Uri.parse('http://$ip:8080/api/v1/sync/heartbeat'),
          body: jsonEncode({'terminalName': terminalName}),
        ).timeout(const Duration(seconds: 3));
      } catch (_) {
        // Ignore heartbeat failures to avoid cluttering logs
      }
    });
  }

  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  void dispose() {
    stopAutoSync();
  }

  Future<SyncResult> connectAndSync(String ip) async {
    final baseUrl = 'http://$ip:8080';
    try {
      final prefs = await SharedPreferences.getInstance();
      final terminalName = prefs.getString('terminal_name') ?? 'Unknown Terminal';
      
      final url = Uri.parse('$baseUrl/api/v1/sync/init').replace(
        queryParameters: {'terminalName': terminalName},
      );
      
      final response = await http.get(url)
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode != 200) {
        return SyncResult(
          success: false, 
          message: 'Server returned error: ${response.statusCode}',
          troubleshootingStep: 'Ensure the Desktop app is running and a tenant is logged in.'
        );
      }

      final data = jsonDecode(response.body);
      final tenantId = data['tenantId'] as String;
      final branchId = data['branchId'] as String?;
      final warehouseId = data['warehouseId'] as String?; // NEW: Extract Warehouse Identity
      final tierId = data['tierId'] as String?; // Parse tierId from Desktop
      final configData = data['config'] as Map<String, dynamic>?;

      // Persist locally
      await prefs.setString('server_ip', ip);
      await prefs.setBool('is_mobile_configured', true);
      await prefs.setString('last_synced_tenant_id', tenantId);

      // Update Global State
      ApiConfig.setBaseUrl(baseUrl);
      ApiConfig.setFlavor(AppFlavor.prod);
      
      final currentConfig = await _configRepo.getConfiguration();
      final newConfig = currentConfig.copyWith(
        tenantId: tenantId,
        branchId: branchId,
        warehouseId: warehouseId,
        tierId: tierId,
        isConfigured: true,
      );

      // Only save if configuration changed
      if (newConfig != currentConfig) {
        await _configRepo.saveConfiguration(newConfig);
        debugPrint('App configuration updated');
      }

      if (configData != null) {
        final configDao = getIt<TenantConfigDao>();
        final existingConfig = await configDao.getConfig(tenantId);
        
        String? finalLogoPath = configData['logoPath'];
        final serverLogoPath = configData['logoPath'] as String?;
        final lastSyncedLogoPath = prefs.getString('last_synced_server_logo_path');

        // Optimized Logo Download
        if (serverLogoPath != null && serverLogoPath.isNotEmpty) {
          // Only download if logo path from server changed or we don't have a local logo
          if (serverLogoPath != lastSyncedLogoPath || existingConfig?.logoPath == null) {
            try {
              final logoResp = await http.get(Uri.parse('$baseUrl/api/v1/sync/logo'))
                  .timeout(const Duration(seconds: 10));
              
              if (logoResp.statusCode == 200) {
                final docDir = await getApplicationDocumentsDirectory();
                // Use a stable filename based on tenant ID to avoid redundant files
                final fileName = 'logo_${tenantId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.png'; 
                final savedImage = File(p.join(docDir.path, fileName));
                await savedImage.writeAsBytes(logoResp.bodyBytes);
                
                finalLogoPath = savedImage.path;
                await prefs.setString('last_synced_server_logo_path', serverLogoPath);
                debugPrint('Logo downloaded successfully to $finalLogoPath');
              } else {
                debugPrint('Failed to sync logo from server: ${logoResp.statusCode}');
                finalLogoPath = existingConfig?.logoPath; // Keep existing if download fails
              }
            } catch(e) {
              debugPrint('Error downloading logo image: $e');
              finalLogoPath = existingConfig?.logoPath;
            }
          } else {
            // Logo hasn't changed on server, reuse local path
            finalLogoPath = existingConfig?.logoPath;
          }
        }

        // Detect if TenantConfig actually changed
        final shouldUpdateTenantConfig = existingConfig == null ||
            existingConfig.logoPath != finalLogoPath ||
            existingConfig.primaryColor != configData['primaryColor'] ||
            existingConfig.secondaryColor != configData['secondaryColor'] ||
            existingConfig.backgroundPath != configData['backgroundPath'] ||
            existingConfig.appName != configData['appName'] ||
            existingConfig.welcomeMessage != configData['welcomeMessage'];

        if (shouldUpdateTenantConfig) {
          await configDao.saveConfig(
            drift_db.TenantConfigsCompanion(
              tenantId: drift.Value(tenantId),
              logoPath: drift.Value(finalLogoPath),
              primaryColor: drift.Value(configData['primaryColor']),
              secondaryColor: drift.Value(configData['secondaryColor']),
              backgroundPath: drift.Value(configData['backgroundPath']),
              appName: drift.Value(configData['appName']),
              welcomeMessage: drift.Value(configData['welcomeMessage']),
            )
          );
          debugPrint('Tenant configuration updated');
        }
      }

      return SyncResult(success: true, message: 'Connected to $tenantId');
    } catch (e) {
      debugPrint('Sync Error: $e');
      String msg = 'Connection failed';
      String hint = 'Check if the IP address is correct.';

      if (e is TimeoutException) {
        msg = 'Connection timed out';
        hint = 'The server didn\'t react. Check if both devices are on the SAME Wi-Fi.';
      } else if (e.toString().contains('SocketException')) {
        if (e.toString().contains('Connection refused')) {
          msg = 'Connection refused';
          hint = 'Check if port 8080 is open in your computer\'s Firewall settings.';
        } else if (e.toString().contains('Network is unreachable')) {
          msg = 'Network unreachable';
          hint = 'Device has no route to the server. Check Wi-Fi or use 10.0.2.2 for emulators.';
        }
      }

      return SyncResult(
        success: false, 
        message: msg,
        troubleshootingStep: hint
      );
    }
  }

  Future<bool> checkHealth() async {
    final baseUrl = ApiConfig.baseUrl;
    if (baseUrl.isEmpty) return false;
    
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/v1/health'))
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
