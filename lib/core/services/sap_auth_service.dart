import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sss/core/utils/http_client_factory.dart';

class SapAuthService {
  static const _sessionKey = 'b1_session_id';
  static const _serverIpKey = 'server_ip';
  static const _companyDbKey = 'sap_company_db';
  static const _usernameKey = 'sap_username';
  static const _passwordKey = 'sap_password';

  final http.Client client;

    SapAuthService({http.Client? client})
      : client = client ?? createSapHttpClient();

  // ─── Save SAP Credentials ────────────────────────────────────────────────

  Future<void> saveCredentials({
    required String serverIp,
    required String companyDb,
    required String username,
    required String password,
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

        if (sessionId != null && sessionId.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_sessionKey, sessionId);

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
    final serverIp = prefs.getString(_serverIpKey);

    debugPrint('SAP LOGOUT → sessionId: $sessionId, serverIp: $serverIp');

    if (sessionId != null &&
        sessionId.isNotEmpty &&
        serverIp != null &&
        serverIp.isNotEmpty) {
      try {
        final response = await client.post(
          Uri.parse('https://$serverIp:50000/b1s/v1/Logout'),
          headers: {
            'Cookie': 'B1SESSION=$sessionId',
            'Content-Type': 'application/json',
          },
        );
        debugPrint('SAP LOGOUT STATUS → ${response.statusCode}');
      } catch (e) {
        debugPrint('SAP LOGOUT ERROR → $e');
      }
    }

    await prefs.remove(_sessionKey);
    debugPrint('SAP LOGOUT → session cleared');
  }

  // ─── Clear All SAP Config ─────────────────────────────────────────────────

  Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_serverIpKey);
    await prefs.remove(_companyDbKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_passwordKey);
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