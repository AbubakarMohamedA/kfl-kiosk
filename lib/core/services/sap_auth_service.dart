import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sss/core/utils/http_client_factory.dart';
import 'package:sss/di/injection.dart';
import 'package:sss/core/configuration/domain/repositories/configuration_repository.dart';
import 'package:sss/features/auth/domain/services/tenant_service.dart';

class SapAuthService {
  static const _sessionKey = 'b1_session_id';
  static const _routeIdKey = 'sap_route_id';
  static const _serverIpKey = 'server_ip';
  static const _companyDbKey = 'sap_company_db';
  static const _usernameKey = 'sap_username';
  static const _passwordKey = 'sap_password';
  static const _walkInCardCodeKey = 'sap_walkin_card_code';
  static const _currencyCodeKey = 'sap_currency_code';
  static const _warehouseCodeKey = 'sap_warehouse_code';
  static const _bplIdKey = 'sap_bpl_id';
  static const _paymentGlAccountKey = 'sap_payment_gl_account';
  static const _overrideCardCodeKey = 'sap_override_card_code';
  static const _overrideStartDateKey = 'sap_override_start_date';
  static const _overrideEndDateKey = 'sap_override_end_date';
  static const _scheduledSyncTimeKey = 'sap_scheduled_sync_time';
  static const _lastCompanyDbKey = 'sap_last_login_company_db';
  static const _lastServerIpKey = 'sap_last_login_server_ip';
  static const _activeCustomerKey = 'sap_active_customer_code';
  static const _activeCustomerNameKey = 'sap_active_customer_name';

  final http.Client client;
  Timer? _sessionRefreshTimer;

    SapAuthService({http.Client? client})
      : client = client ?? createSapHttpClient();

  void _startAutoRefresh() {
    _sessionRefreshTimer?.cancel();
    _sessionRefreshTimer = Timer.periodic(
      const Duration(minutes: 25),
      (timer) async {
        debugPrint('SapAuthService → Auto-refreshing SAP session (25m trigger)...');
        final isConfig = await isConfigured();
        if (isConfig) {
          await login();
        } else {
          timer.cancel();
        }
      },
    );
  }

  // ─── Save SAP Credentials ────────────────────────────────────────────────

  Future<void> saveCredentials({
    required String serverIp,
    required String companyDb,
    required String username,
    required String password,
    String? walkInCardCode,
    String? currencyCode,
    String? warehouseCode,
    String? bplId,
    String? paymentGlAccount,
    String? overrideCardCode,
    String? overrideStartDate,
    String? overrideEndDate,
    String? scheduledSyncTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Clean server IP before saving — strip protocol and path
    final cleanIp = serverIp
        .replaceAll('https://', '')
        .replaceAll('http://', '')
        .replaceAll('/b1s/v1', '')
        .replaceAll(':50000', '')
        .trim();

    final currentIp = prefs.getString(_serverIpKey);
    final currentDb = prefs.getString(_companyDbKey);

    // If critical parameters changed, invalidate the existing session
    if (currentIp != cleanIp || currentDb != companyDb.trim()) {
      debugPrint('SapAuthService → Config changed, invalidating session.');
      _sessionRefreshTimer?.cancel();
      await prefs.remove(_sessionKey);
      await prefs.remove(_routeIdKey);
    }

    await prefs.setString(_serverIpKey, cleanIp);
    await prefs.setString(_companyDbKey, companyDb.trim());
    await prefs.setString(_usernameKey, username.trim());
    await prefs.setString(_passwordKey, password.trim());
    if (walkInCardCode != null) {
      await prefs.setString(_walkInCardCodeKey, walkInCardCode.trim());
    }
    if (currencyCode != null) {
      await prefs.setString(_currencyCodeKey, currencyCode.trim());
    }
    if (warehouseCode != null) {
      await prefs.setString(_warehouseCodeKey, warehouseCode.trim());
    }
    if (bplId != null) {
      await prefs.setString(_bplIdKey, bplId.trim());
    }
    if (paymentGlAccount != null) {
      await prefs.setString(_paymentGlAccountKey, paymentGlAccount.trim());
    }
    if (overrideCardCode != null) {
      await prefs.setString(_overrideCardCodeKey, overrideCardCode.trim());
    }
    if (overrideStartDate != null) {
      await prefs.setString(_overrideStartDateKey, overrideStartDate.trim());
    }
    if (overrideEndDate != null) {
      await prefs.setString(_overrideEndDateKey, overrideEndDate.trim());
    }
    if (scheduledSyncTime != null) {
      await prefs.setString(_scheduledSyncTimeKey, scheduledSyncTime.trim());
    }

    debugPrint('SAP Credentials saved:');
    debugPrint('  server_ip → $cleanIp');
    debugPrint('  companyDb → ${companyDb.trim()}');
    debugPrint('  username  → ${username.trim()}');
    debugPrint('  password  → [hidden]');
  }

  // ─── Load SAP Credentials ────────────────────────────────────────────────

  Future<Map<String, String?>> loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    
    String? serverIp = prefs.getString(_serverIpKey);
    String? companyDb = prefs.getString(_companyDbKey);
    String? username = prefs.getString(_usernameKey);
    String? password = prefs.getString(_passwordKey);

    // --- Inherit from Branch / Tenant if not overridden locally ---
    if (serverIp == null || companyDb == null || username == null || password == null) {
      try {
        final configRepo = getIt<ConfigurationRepository>();
        final config = await configRepo.getConfiguration();
        final tenantId = config.tenantId;
        final branchId = config.branchId;

        final tenantService = TenantService();
        
        // 1. Check if running as Branch and Branch has credentials
        if (branchId != null) {
          final branch = await tenantService.getBranchById(branchId);
          if (branch != null) {
            serverIp = branch.sapServerIp ?? serverIp;
            companyDb = branch.sapCompanyDb ?? companyDb;
            username = branch.sapUsername ?? username;
            password = branch.sapPassword ?? password;
          }
        }

        // 2. Fallback to Tenant level
        if (tenantId != null && (serverIp == null || companyDb == null || username == null || password == null)) {
          final tenants = tenantService.getTenants();
          final tenant = tenants.firstWhere((t) => t.id == tenantId);
          serverIp = tenant.sapServerIp ?? serverIp;
          companyDb = tenant.sapCompanyDb ?? companyDb;
          username = tenant.sapUsername ?? username;
          password = tenant.sapPassword ?? password;
        }
      } catch (e) {
        debugPrint('SapAuthService fallback error: $e');
      }
    }

    return {
      'serverIp': serverIp,
      'companyDb': companyDb,
      'username': username,
      'password': password,
      'walkInCardCode': prefs.getString(_walkInCardCodeKey),
      'currencyCode': prefs.getString(_currencyCodeKey),
      'warehouseCode': prefs.getString(_warehouseCodeKey), // NEW
      'bplId': prefs.getString(_bplIdKey),
      'paymentGlAccount': prefs.getString(_paymentGlAccountKey),
      'overrideCardCode': prefs.getString(_overrideCardCodeKey),
      'overrideStartDate': prefs.getString(_overrideStartDateKey),
      'overrideEndDate': prefs.getString(_overrideEndDateKey),
      'scheduledSyncTime': prefs.getString(_scheduledSyncTimeKey),
    };
  }

  // ─── Check if SAP is configured ───────────────────────────────────────────
  // Returns true if we have either:
  //   a) a valid active session, OR
  //   b) full credentials saved (can re-login)

  Future<bool> isConfigured() async {
    final prefs = await SharedPreferences.getInstance();

    final sessionId = prefs.getString(_sessionKey);
    final hasSession = sessionId != null && sessionId.isNotEmpty;
    
    final creds = await loadCredentials();
    final serverIp = creds['serverIp'];
    final companyDb = creds['companyDb'];
    final username = creds['username'];
    final password = creds['password'];

    final hasCredentials = serverIp != null &&
        serverIp.isNotEmpty &&
        companyDb != null &&
        companyDb.isNotEmpty &&
        username != null &&
        username.isNotEmpty &&
        password != null &&
        password.isNotEmpty;

    debugPrint('SapAuthService.isConfigured:');
    debugPrint('  hasSession     → $hasSession (${sessionId ?? 'null'})');
    debugPrint('  hasCredentials → $hasCredentials');
    debugPrint('  result         → ${hasSession || hasCredentials}');

    return hasSession || hasCredentials;
  }

  // ─── Get Active Session ID ────────────────────────────────────────────────

  Future<String?> getSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString(_sessionKey);
    if (sessionId == null || sessionId.isEmpty) return null;

    // Consistency Check: Does the current session belong to the current config?
    final currentIp = prefs.getString(_serverIpKey);
    final currentDb = prefs.getString(_companyDbKey);
    final lastIp = prefs.getString(_lastServerIpKey);
    final lastDb = prefs.getString(_lastCompanyDbKey);

    if (currentIp != lastIp || currentDb != lastDb) {
      debugPrint('SapAuthService → Session mismatch detected (Config changed since login).');
      debugPrint('  Expected: $lastIp / $lastDb');
      debugPrint('  Current: $currentIp / $currentDb');
      // Do NOT return the stale session
      return null;
    }

    return sessionId;
  }

  // ─── Get Active Card Code (with Override Logic) ───────────────────────────

  Future<String?> getActiveCardCode() async {
    final prefs = await SharedPreferences.getInstance();

    // Priority 1: Per-transaction active customer (set via the Active Customer button)
    final activeCode = prefs.getString(_activeCustomerKey);
    if (activeCode != null && activeCode.isNotEmpty) {
      debugPrint('SapAuthService → Using Active Customer: $activeCode');
      return activeCode;
    }

    final walkInCode = prefs.getString(_walkInCardCodeKey);
    final overrideCode = prefs.getString(_overrideCardCodeKey);
    final startStr = prefs.getString(_overrideStartDateKey);
    final endStr = prefs.getString(_overrideEndDateKey);
    
    if (overrideCode == null || overrideCode.isEmpty || startStr == null || endStr == null) {
      return walkInCode;
    }
    
    try {
      final now = DateTime.now();
      // Only compare date part to avoid time-of-day issues
      final today = DateTime(now.year, now.month, now.day);
      
      final startDate = DateTime.parse(startStr);
      final endDate = DateTime.parse(endStr);
      
      if ((today.isAfter(startDate) || today.isAtSameMomentAs(startDate)) && 
          (today.isBefore(endDate) || today.isAtSameMomentAs(endDate))) {
        debugPrint('SapAuthService → Applying Customer Override: $overrideCode (Rule Active)');
        return overrideCode;
      }
    } catch (e) {
      debugPrint('SapAuthService → Error parsing override dates: $e');
    }
    
    return walkInCode;
  }

  // ─── Active Transaction Customer ──────────────────────────────────────────
  // Stored per-session, overrides the walk-in default for each transaction.

  Future<void> saveActiveCustomer(String cardCode, String cardName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeCustomerKey, cardCode);
    await prefs.setString(_activeCustomerNameKey, cardName);
    debugPrint('SapAuthService → Active Customer set to: $cardCode ($cardName)');
  }

  Future<void> clearActiveCustomer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeCustomerKey);
    await prefs.remove(_activeCustomerNameKey);
    debugPrint('SapAuthService → Active Customer cleared');
  }

  Future<Map<String, String?>> getActiveCustomer() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'cardCode': prefs.getString(_activeCustomerKey),
      'cardName': prefs.getString(_activeCustomerNameKey),
    };
  }

  // ─── Get Route ID (Load Balancer Cookie) ──────────────────────────────────

  Future<String?> getRouteId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_routeIdKey);
  }

  // ─── Get Unified Headers ──────────────────────────────────────────────────
  // Includes Session, RouteID, and Cache Control
  
  Future<Map<String, String>> getHeaders() async {
    final sessionId = await getSessionId();
    final routeId = await getRouteId();
    
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
    };

    if (sessionId != null && sessionId.isNotEmpty) {
      String cookie = 'B1SESSION=$sessionId';
      if (routeId != null && routeId.isNotEmpty) {
        cookie += '; ROUTEID=$routeId';
      }
      headers['Cookie'] = cookie;
    }

    return headers;
  }

  Future<bool> ensureSession({bool force = false}) async {
    if (!force) {
      final sessionId = await getSessionId();
      if (sessionId != null && sessionId.isNotEmpty) {
        return true;
      }
    }
    final loginResult = await login();
    return loginResult.success;
  }

  // ─── Login ──────────────────────────────────────────────────────────────────

  // ─── Get Base URL ─────────────────────────────────────────────────────────

  Future<String> getBaseUrl() async {
    final creds = await loadCredentials();
    String serverIp = creds['serverIp'] ?? '';

    // Safety clean — in case something slipped through
    serverIp = serverIp
        .replaceAll('https://', '')
        .replaceAll('http://', '')
        .replaceAll('/b1s/v1', '')
        .replaceAll(':50000', '')
        .trim();

    final url = 'https://$serverIp:50000/b1s/v1';
    debugPrint('SapAuthService.getBaseUrl → $url');
    return url;
  }

  // ─── Login to SAP Service Layer ───────────────────────────────────────────

  Future<SapLoginResult> login() async {
    final creds = await loadCredentials();

    final serverIp = creds['serverIp'];
    final companyDb = creds['companyDb'];
    final username = creds['username'];
    final password = creds['password'];

    debugPrint('═══════════════════════════════════════');
    debugPrint('SAP LOGIN ATTEMPT');
    debugPrint('  serverIp  → $serverIp');
    debugPrint('  companyDb → $companyDb');
    debugPrint('  username  → $username');
    debugPrint('  password  → [hidden]');
    debugPrint('═══════════════════════════════════════');

    if (serverIp == null ||
        serverIp.isEmpty ||
        companyDb == null ||
        companyDb.isEmpty ||
        username == null ||
        username.isEmpty ||
        password == null ||
        password.isEmpty) {
      debugPrint('SAP LOGIN FAILED → credentials not configured');
      return SapLoginResult(
        success: false,
        message: 'SAP credentials not configured.',
      );
    }

    final uri = Uri.parse('https://$serverIp:50000/b1s/v1/Login');
    debugPrint('SAP LOGIN URL → $uri');

    try {
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'CompanyDB': companyDb,
          'UserName': username,
          'Password': password,
        }),
      );

      debugPrint('SAP LOGIN STATUS → ${response.statusCode}');
      debugPrint('SAP LOGIN BODY   → ${response.body.substring(0, response.body.length.clamp(0, 300))}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessionId = data['SessionId'];

        // Extract ROUTEID from Set-Cookie for load-balanced SAP environments
        String? routeId;
        final rawCookie = response.headers['set-cookie'];
        if (rawCookie != null) {
          final match = RegExp(r'ROUTEID=([^;]+)').firstMatch(rawCookie);
          if (match != null) {
            routeId = match.group(1);
            debugPrint('SAP LOGIN → Found ROUTEID: $routeId');
          }
        }

          if (sessionId != null && sessionId.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_sessionKey, sessionId);
          
          // Store the config that created this session for consistency checks
          await prefs.setString(_lastServerIpKey, serverIp);
          await prefs.setString(_lastCompanyDbKey, companyDb);

          if (routeId != null) {
            await prefs.setString(_routeIdKey, routeId);
          } else {
            await prefs.remove(_routeIdKey);
          }

          debugPrint('SAP LOGIN SUCCESS → SessionId: $sessionId');
          _startAutoRefresh();

          return SapLoginResult(
            success: true,
            message: 'Logged in successfully',
            sessionId: sessionId,
          );
        } else {
          debugPrint('SAP LOGIN FAILED → No SessionId in response');
          return SapLoginResult(
            success: false,
            message: 'Login succeeded but no session ID returned.',
          );
        }
      } else {
        final error = _parseError(response.body);
        debugPrint('SAP LOGIN FAILED → $error');
        return SapLoginResult(
          success: false,
          message: error,
        );
      }
    } catch (e) {
      debugPrint('SAP LOGIN EXCEPTION → $e');
      return SapLoginResult(
        success: false,
        message: 'Connection failed: $e',
      );
    }
  }

  // ─── Logout from SAP ──────────────────────────────────────────────────────

  Future<void> logout() async {
    _sessionRefreshTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString(_sessionKey);
    final routeId = prefs.getString(_routeIdKey);
    final serverIp = prefs.getString(_serverIpKey);

    debugPrint('SAP LOGOUT → sessionId: $sessionId, serverIp: $serverIp');

    if (sessionId != null &&
        sessionId.isNotEmpty &&
        serverIp != null &&
        serverIp.isNotEmpty) {
      try {
        String cookie = 'B1SESSION=$sessionId';
        if (routeId != null) cookie += '; ROUTEID=$routeId';

        final response = await client.post(
          Uri.parse('https://$serverIp:50000/b1s/v1/Logout'),
          headers: {
            'Cookie': cookie,
            'Content-Type': 'application/json',
          },
        );
        debugPrint('SAP LOGOUT STATUS → ${response.statusCode}');
      } catch (e) {
        debugPrint('SAP LOGOUT ERROR → $e');
      }
    }

    await prefs.remove(_sessionKey);
    await prefs.remove(_routeIdKey);
    debugPrint('SAP LOGOUT → session cleared');
  }

  // ─── Clear All SAP Config ─────────────────────────────────────────────────

  Future<void> clearConfig() async {
    _sessionRefreshTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_routeIdKey);
    await prefs.remove(_serverIpKey);
    await prefs.remove(_companyDbKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_passwordKey);
    await prefs.remove(_walkInCardCodeKey);
    await prefs.remove(_currencyCodeKey);
    await prefs.remove(_warehouseCodeKey);
    await prefs.remove(_bplIdKey);
    await prefs.remove(_paymentGlAccountKey);
    await prefs.remove(_overrideCardCodeKey);
    await prefs.remove(_overrideStartDateKey);
    await prefs.remove(_overrideEndDateKey);
    await prefs.remove(_scheduledSyncTimeKey);
    await prefs.remove(_lastCompanyDbKey);
    await prefs.remove(_lastServerIpKey);
    debugPrint('SAP CONFIG → all credentials and session cleared');
  }

  // ─── Search Business Partners ───────────────────────────────────────────────

  Future<SapBpQueryResult> searchBusinessPartners(String query,
      {String? nextLink}) async {
    try {
      final sessionId = await getSessionId();
      final routeId = await getRouteId();
      if (sessionId == null || sessionId.isEmpty) {
        return SapBpQueryResult(value: []);
      }

      String cookie = 'B1SESSION=$sessionId';
      if (routeId != null) cookie += '; ROUTEID=$routeId';

      final baseUrl = await getBaseUrl();

      Uri uri;
      if (nextLink != null) {
        // nextLink is usually /b1s/v1/BusinessPartners?... or BusinessPartners?...
        final cleanNext =
            nextLink.startsWith('/') ? nextLink : '/b1s/v1/$nextLink';
        // Base URL already includes /b1s/v1, so we need to be careful
        final rootUrl = baseUrl.replaceAll('/b1s/v1', '');
        uri = Uri.parse('$rootUrl$cleanNext');
      } else {
        final trimmedQuery = query.trim();
        // We don't lowercase on Dart side because we removed tolower on SAP side.
        // This allows the user to type the exact casing if they are on a case-sensitive DB (HANA),
        // while SQL Server users remain case-insensitive by default.
        final safeQuery = trimmedQuery.replaceAll('\'', '\'\'');

        final typeFilter = '(CardType eq \'cCustomer\' or CardType eq \'cLid\')';
        final filter = trimmedQuery.isEmpty
            ? typeFilter
            : '$typeFilter and (contains(CardCode, \'$safeQuery\') or contains(CardName, \'$safeQuery\'))';

        uri = Uri.parse('$baseUrl/BusinessPartners').replace(queryParameters: {
          '\$select': 'CardCode,CardName',
          '\$filter': filter,
          '\$top': '500',
        });
      }

      final response = await client.get(
        uri,
        headers: {
          'Cookie': cookie,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cache-Control': 'no-cache', // ✅ Ensure no stale results from service layer
          'Pragma': 'no-cache',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['value'] ?? [];
        final String? next = data['odata.nextLink'];

        return SapBpQueryResult(
          value: items.map((item) {
            return {
              'CardCode': (item['CardCode'] ?? '').toString(),
              'CardName': (item['CardName'] ?? '').toString(),
            };
          }).toList(),
          nextLink: next,
        );
      } else {
        final errorMsg = _parseError(response.body);
        debugPrint(
            'SapAuthService.searchBusinessPartners error: ${response.statusCode} - $errorMsg');
        throw Exception('SAP Search Error: $errorMsg');
      }
    } catch (e) {
      debugPrint('SapAuthService.searchBusinessPartners exception: $e');
      rethrow;
    }
  }

  // ─── Parse SAP Error ──────────────────────────────────────────────────────

  String _parseError(String body) {
    try {
      final json = jsonDecode(body);
      return json['error']['message']['value'] ?? body;
    } catch (_) {
      return body;
    }
  }
}

// ─── Result Model ─────────────────────────────────────────────────────────────

class SapLoginResult {
  final bool success;
  final String message;
  final String? sessionId;

  SapLoginResult({
    required this.success,
    required this.message,
    this.sessionId,
  });

  @override
  String toString() =>
      'SapLoginResult(success: $success, message: $message, sessionId: $sessionId)';
}
class SapBpQueryResult {
  final List<Map<String, String>> value;
  final String? nextLink;

  SapBpQueryResult({required this.value, this.nextLink});
}
