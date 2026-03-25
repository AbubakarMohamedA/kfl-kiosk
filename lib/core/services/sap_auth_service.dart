import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sss/core/utils/http_client_factory.dart';

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
  static const _taxCodeKey = 'sap_tax_code'; // NEW
  static const _paymentGlAccountKey = 'sap_payment_gl_account'; // NEW

  final http.Client client;

    SapAuthService({http.Client? client})
      : client = client ?? createSapHttpClient();

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
    String? taxCode, // NEW
    String? paymentGlAccount, // NEW
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Clean server IP before saving — strip protocol and path
    final cleanIp = serverIp
        .replaceAll('https://', '')
        .replaceAll('http://', '')
        .replaceAll('/b1s/v1', '')
        .replaceAll(':50000', '')
        .trim();

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
    if (taxCode != null) {
      await prefs.setString(_taxCodeKey, taxCode.trim());
    }
    if (paymentGlAccount != null) {
      await prefs.setString(_paymentGlAccountKey, paymentGlAccount.trim());
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
    return {
      'serverIp': prefs.getString(_serverIpKey),
      'companyDb': prefs.getString(_companyDbKey),
      'username': prefs.getString(_usernameKey),
      'password': prefs.getString(_passwordKey),
      'walkInCardCode': prefs.getString(_walkInCardCodeKey),
      'currencyCode': prefs.getString(_currencyCodeKey),
      'warehouseCode': prefs.getString(_warehouseCodeKey), // NEW
      'bplId': prefs.getString(_bplIdKey),
      'taxCode': prefs.getString(_taxCodeKey), // NEW
      'paymentGlAccount': prefs.getString(_paymentGlAccountKey), // NEW
    };
  }

  // ─── Check if SAP is configured ───────────────────────────────────────────
  // Returns true if we have either:
  //   a) a valid active session, OR
  //   b) full credentials saved (can re-login)

  Future<bool> isConfigured() async {
    final prefs = await SharedPreferences.getInstance();

    final sessionId = prefs.getString(_sessionKey);
    final serverIp = prefs.getString(_serverIpKey);
    final companyDb = prefs.getString(_companyDbKey);
    final username = prefs.getString(_usernameKey);
    final password = prefs.getString(_passwordKey);

    final hasSession = sessionId != null && sessionId.isNotEmpty;
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
    return prefs.getString(_sessionKey);
  }

  // ─── Get Route ID (Load Balancer Cookie) ──────────────────────────────────

  Future<String?> getRouteId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_routeIdKey);
  }

  // ─── Get Base URL ─────────────────────────────────────────────────────────

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    String serverIp = prefs.getString(_serverIpKey) ?? '';

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
          if (routeId != null) {
            await prefs.setString(_routeIdKey, routeId);
          } else {
            await prefs.remove(_routeIdKey);
          }

          debugPrint('SAP LOGIN SUCCESS → SessionId: $sessionId');

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
    await prefs.remove(_taxCodeKey); // NEW
    debugPrint('SAP CONFIG → all credentials and session cleared');
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