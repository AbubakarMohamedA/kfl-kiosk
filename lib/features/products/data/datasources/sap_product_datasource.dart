import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sss/features/products/data/models/product_model.dart';
import 'package:sss/features/products/data/datasources/product_remote_datasource.dart';
import 'package:sss/core/services/sap_auth_service.dart';

class SapProductDataSource implements ProductDataSource {
  final SapAuthService _sapAuthService;
  final http.Client client;

  Map<int, String> _groupCache = {};

  // Storage Keys
  static const _sapProductsCacheKey = 'sap_products_cache';
  static const _sapLastFetchKey = 'sap_last_fetch_time';
  static const _sapUploadedImagesKey = 'sap_uploaded_images';

  // ✅ In-memory product cache to prevent double-fetches
  List<ProductModel>? _cachedProducts;
  DateTime? _lastFetchTime;

  // ✅ In-memory image mapping for uploaded SAP images
  final Map<String, String> _uploadedImages = {};

  // ✅ Persist flag to ensure init only runs once
  bool _isInitialized = false;

  void updateLocalImage(String productId, String imageUrl) {
    _uploadedImages[productId] = imageUrl;

    // Also update the cached product list immediately
    if (_cachedProducts != null) {
      for (int i = 0; i < _cachedProducts!.length; i++) {
        if (_cachedProducts![i].id == productId) {
          _cachedProducts![i] = _cachedProducts![i].copyWith(imageUrl: imageUrl);
          break; // Stop after finding the product
        }
      }
    }

    _savePersistence(); // Save mapping to disk
  }

  // ✅ Fetch lock — prevents concurrent duplicate fetches
  bool _isFetching = false;
  Completer<List<ProductModel>>? _fetchCompleter;

  SapProductDataSource(this._sapAuthService, {http.Client? client})
      : client = client ?? http.Client();

  // ─── Persistence Logic ───────────────────────────────────────────────

  Future<void> _initPersistence() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Load Uploaded Images (always persistent across days)
      final imagesJson = prefs.getString(_sapUploadedImagesKey);
      if (imagesJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(imagesJson);
        decoded.forEach((key, value) {
          _uploadedImages[key] = value.toString();
        });
      }

      // 2. Load Product Cache
      final timeStr = prefs.getString(_sapLastFetchKey);
      final productsJson = prefs.getString(_sapProductsCacheKey);

      if (timeStr != null && productsJson != null) {
        final lastFetchTime = DateTime.parse(timeStr);
        final now = DateTime.now();

        // Only restore if it's the same day
        if (now.year == lastFetchTime.year &&
            now.month == lastFetchTime.month &&
            now.day == lastFetchTime.day) {
          final List<dynamic> decoded = jsonDecode(productsJson);
          _cachedProducts = decoded.map((p) => ProductModel.fromJson(p)).toList();
          _lastFetchTime = lastFetchTime;
          debugPrint('SapProductDataSource → Persistent cache restored (${_cachedProducts!.length} products).');
        }
      }
    } catch (e) {
      debugPrint('SapProductDataSource → _initPersistence error: $e');
    } finally {
      _isInitialized = true;
    }
  }

  Future<void> _savePersistence() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save Uploaded Images
      await prefs.setString(_sapUploadedImagesKey, jsonEncode(_uploadedImages));

      // Save Products and Time
      if (_cachedProducts != null && _lastFetchTime != null) {
        final productsJson = jsonEncode(_cachedProducts!.map((p) => p.toJson()).toList());
        await prefs.setString(_sapProductsCacheKey, productsJson);
        await prefs.setString(_sapLastFetchKey, _lastFetchTime!.toIso8601String());
      }
    } catch (e) {
      debugPrint('SapProductDataSource → _savePersistence error: $e');
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<String> _getBaseUrl() async {
    return _sapAuthService.getBaseUrl();
  }

  Future<Map<String, String>> _getHeaders() async {
    final sessionId = await _sapAuthService.getSessionId() ?? '';
    debugPrint('SapProductDataSource → B1SESSION: $sessionId');
    return {
      'Cookie': 'B1SESSION=$sessionId',
      'Content-Type': 'application/json',
    };
  }

  // ─── Ensure Valid Session ─────────────────────────────────────────────────
  // Only logs in if no session exists — does NOT force a new login

  Future<void> _ensureSession() async {
    final sessionId = await _sapAuthService.getSessionId();

    if (sessionId == null || sessionId.isEmpty) {
      debugPrint('SapProductDataSource → No session, attempting auto login...');
      final loginResult = await _sapAuthService.login();
      if (!loginResult.success) {
        throw Exception('SAP Login failed: ${loginResult.message}');
      }
      debugPrint('SapProductDataSource → Auto login success: ${loginResult.sessionId}');
    } else {
      debugPrint('SapProductDataSource → Session exists: $sessionId');
    }
  }

  // ─── Re-login on 401 ──────────────────────────────────────────────────────

  Future<Map<String, String>> _reloginAndGetHeaders() async {
    debugPrint('SapProductDataSource → Re-logging in...');
    final loginResult = await _sapAuthService.login();
    if (!loginResult.success) {
      throw Exception('SAP re-login failed: ${loginResult.message}');
    }
    debugPrint('SapProductDataSource → Re-login success: ${loginResult.sessionId}');
    return _getHeaders();
  }

  // ─── Load Item Groups Dynamically ─────────────────────────────────────────

  Future<void> _loadItemGroups() async {
    if (_groupCache.isNotEmpty) return;

    final baseUrl = await _getBaseUrl();
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/ItemGroups?\$select=Number,GroupName');

    debugPrint('SapProductDataSource → Loading item groups: $uri');

    try {
      final response = await client.get(uri, headers: headers);
      debugPrint('SapProductDataSource → ItemGroups status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List groups = data['value'] ?? [];

        _groupCache = {
          for (final g in groups)
            (g['Number'] as int): (g['GroupName'] as String? ?? 'Unknown'),
        };

        debugPrint('SapProductDataSource → Loaded ${_groupCache.length} groups: $_groupCache');
      }
    } catch (e) {
      debugPrint('SapProductDataSource → Failed to load item groups: $e');
      // silently fail — category falls back to 'Group X'
    }
  }

  String _mapGroupCode(dynamic code) {
    return _groupCache[code] ?? 'Group $code';
  }

  // ─── Map SAP Item to ProductModel ─────────────────────────────────────────

  ProductModel _mapToProductModel(Map<String, dynamic> item) {
    final String id = item['ItemCode'] ?? '';
    final String placeholder = 'assets/images/placeholder.png';
    return ProductModel(
      id: id,
      name: item['ItemName'] ?? '',
      brand: item['Mainsupplier'] ?? '',
      price: (item['AvgStdPrice'] ?? 0.0).toDouble(),
      size: item['InventoryUOM'] ?? '',
      category: _mapGroupCode(item['ItemsGroupCode']),
      description: item['ItemName'] ?? '',
      imageUrl: _uploadedImages.containsKey(id) ? _uploadedImages[id]! : placeholder,
      tenantId: 'enterprise',
      branchId: null,
    );
  }

  // ─── Fetch All Products with Auto Pagination ──────────────────────────────

  @override
  Future<List<ProductModel>> fetchProducts({String? tenantId}) async {
    // Ensuring persistence is initialized
    if (!_isInitialized) await _initPersistence();

    // ✅ If valid cache exists (same day), return it immediately
    if (_cachedProducts != null && _lastFetchTime != null) {
      final now = DateTime.now();
      if (now.year == _lastFetchTime!.year &&
          now.month == _lastFetchTime!.month &&
          now.day == _lastFetchTime!.day) {
        debugPrint('SapProductDataSource → Returning cached products (${_cachedProducts!.length}), avoiding double-fetch.');
        return [..._cachedProducts!];
      }
    }

    // ✅ If a fetch is already in progress, wait for its result
    if (_isFetching && _fetchCompleter != null) {
      debugPrint('SapProductDataSource → Fetch in progress, waiting for result...');
      return _fetchCompleter!.future;
    }

    _isFetching = true;
    _fetchCompleter = Completer<List<ProductModel>>();

    try {
      debugPrint('═══════════════════════════════════════');
      debugPrint('SapProductDataSource.fetchProducts START');
      debugPrint('═══════════════════════════════════════');

      await _ensureSession();

      final baseUrl = await _getBaseUrl();
      debugPrint('SapProductDataSource → baseUrl: $baseUrl');

      // ✅ Clear group cache so it reloads under current session
      _groupCache = {};
      await _loadItemGroups();

      // ✅ SAP B1 returns empty on the very first Items query of a new session.
      // A lightweight $top=0 ping warms up the session context before the
      // real paginated fetch — deterministic, costs no data transfer.
      final warmupUri = Uri.parse('$baseUrl/Items?\$top=0');
      final warmupHeaders = await _getHeaders();
      final warmupResponse = await client.get(warmupUri, headers: warmupHeaders);
      debugPrint('SapProductDataSource → Warmup status: ${warmupResponse.statusCode}');

      final List<ProductModel> allProducts = [];
      int skip = 0;
      const int top = 20;
      bool hasMore = true;

      while (hasMore) {
        var headers = await _getHeaders();

        // ✅ Raw string — $ stays unencoded, SAP parses correctly
        final queryString =
            '\$select=ItemCode,ItemName,ItemsGroupCode,'
            'AvgStdPrice,Mainsupplier,InventoryUOM'
            '&\$skip=$skip'
            '&\$top=$top';

        final uri = Uri.parse('$baseUrl/Items?$queryString');

        debugPrint('SapProductDataSource → Fetching page skip=$skip: $uri');

        var response = await client.get(uri, headers: headers);

        debugPrint('SapProductDataSource → Status: ${response.statusCode}');
        debugPrint(
          'SapProductDataSource → Body preview: '
          '${response.body.substring(0, response.body.length.clamp(0, 500))}',
        );

        // ── Handle 401 ───────────────────────────────────────────────────
        if (response.statusCode == 401) {
          debugPrint('SapProductDataSource → 401, re-logging in...');
          headers = await _reloginAndGetHeaders();
          response = await client.get(uri, headers: headers);
          debugPrint('SapProductDataSource → Retry status: ${response.statusCode}');
        }

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List items = data['value'] ?? [];

          debugPrint('SapProductDataSource → Items in page: ${items.length}');

          for (final item in items) {
            allProducts.add(_mapToProductModel(item));
          }

          hasMore = data.containsKey('odata.nextLink') && items.isNotEmpty;
          skip += top;

          debugPrint(
            'SapProductDataSource → hasMore: $hasMore, '
            'total so far: ${allProducts.length}',
          );
        } else {
          final error = _parseError(response.body);
          debugPrint('SapProductDataSource → FETCH ERROR: $error');
          throw Exception(
            'Failed to fetch products (${response.statusCode}): $error',
          );
        }
      }

      debugPrint(
        'SapProductDataSource → DONE. Total products: ${allProducts.length}',
      );
      debugPrint('═══════════════════════════════════════');

      _cachedProducts = allProducts;
      _lastFetchTime = DateTime.now();

      _savePersistence(); // Save to disk

      _fetchCompleter!.complete(allProducts);
      return allProducts;

    } catch (e) {
      _fetchCompleter!.completeError(e);
      rethrow;
    } finally {
      _isFetching = false;
      _fetchCompleter = null;
    }
  }

  // ─── Get Single Product ───────────────────────────────────────────────────

  @override
  Future<ProductModel?> getProductById(String id) async {
    debugPrint('SapProductDataSource.getProductById → id: $id');

    if (!_isInitialized) await _initPersistence();

    // Try finding in cache first
    if (_cachedProducts != null) {
      final match = _cachedProducts!.where((p) => p.id == id);
      if (match.isNotEmpty) return match.first;
    }

    await _ensureSession();
    await _loadItemGroups();

    final baseUrl = await _getBaseUrl();
    var headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/Items(\'$id\')');

    var response = await client.get(uri, headers: headers);

    if (response.statusCode == 401) {
      headers = await _reloginAndGetHeaders();
      response = await client.get(uri, headers: headers);
    }

    if (response.statusCode == 200) {
      final Map<String, dynamic> item = jsonDecode(response.body);
      debugPrint('SapProductDataSource.getProductById → found: ${item['ItemCode']}');
      return _mapToProductModel(item);
    } else if (response.statusCode == 404) {
      debugPrint('SapProductDataSource.getProductById → not found');
      return null;
    } else {
      final error = _parseError(response.body);
      throw Exception('Failed to fetch product (${response.statusCode}): $error');
    }
  }

  // ─── Add Product ──────────────────────────────────────────────────────────

  @override
  Future<void> addProduct(ProductModel product) async {
    debugPrint('SapProductDataSource.addProduct → id: ${product.id}');

    await _ensureSession();

    final baseUrl = await _getBaseUrl();
    var headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/Items');

    final body = jsonEncode({
      'ItemCode': product.id,
      'ItemName': product.name,
      'Mainsupplier': product.brand.isNotEmpty ? product.brand : null,
      'InventoryUOM': product.size.isNotEmpty ? product.size : null,
      'AvgStdPrice': product.price,
      'ItemType': 'itItems',
      'InventoryItem': 'tYES',
      'SalesItem': 'tYES',
      'PurchaseItem': 'tYES',
      'Valid': 'tYES',
      'Frozen': 'tNO',
    });

    var response = await client.post(uri, headers: headers, body: body);

    if (response.statusCode == 401) {
      headers = await _reloginAndGetHeaders();
      response = await client.post(uri, headers: headers, body: body);
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = _parseError(response.body);
      throw Exception('Failed to add product (${response.statusCode}): $error');
    }

    _cachedProducts = null; // invalidate cache
    debugPrint('SapProductDataSource.addProduct → success: ${product.id}');
  }

  // ─── Update Product ───────────────────────────────────────────────────────

  @override
  Future<void> updateProduct(ProductModel product) async {
    debugPrint('SapProductDataSource.updateProduct → id: ${product.id}');

    await _ensureSession();

    final baseUrl = await _getBaseUrl();
    var headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/Items(\'${product.id}\')');

    // ✅ Never send null values to SAP — omit the field entirely if empty.
    // Sending null causes SAP to clear the field and can corrupt session state.
    final Map<String, dynamic> patchBody = {};

    if (product.name.isNotEmpty) patchBody['ItemName'] = product.name;
    if (product.price > 0) patchBody['AvgStdPrice'] = product.price;
    if (product.size.isNotEmpty) patchBody['InventoryUOM'] = product.size;
    if (product.brand.isNotEmpty) patchBody['Mainsupplier'] = product.brand;

    debugPrint('SapProductDataSource.updateProduct → patchBody: $patchBody');

    final body = jsonEncode(patchBody);

    var response = await client.patch(uri, headers: headers, body: body);

    if (response.statusCode == 401) {
      headers = await _reloginAndGetHeaders();
      response = await client.patch(uri, headers: headers, body: body);
    }

    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = _parseError(response.body);
      throw Exception(
        'Failed to update product (${response.statusCode}): $error',
      );
    }

    _cachedProducts = null; // invalidate cache
    debugPrint('SapProductDataSource.updateProduct → success: ${product.id}');
  }

  // ─── Delete Product ───────────────────────────────────────────────────────

  @override
  Future<void> deleteProduct(String id) async {
    debugPrint('SapProductDataSource.deleteProduct → id: $id');

    await _ensureSession();

    final baseUrl = await _getBaseUrl();
    var headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/Items(\'$id\')');

    var response = await client.delete(uri, headers: headers);

    if (response.statusCode == 401) {
      headers = await _reloginAndGetHeaders();
      response = await client.delete(uri, headers: headers);
    }

    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = _parseError(response.body);
      throw Exception(
        'Failed to delete product (${response.statusCode}): $error',
      );
    }

    _cachedProducts = null; // invalidate cache
    debugPrint('SapProductDataSource.deleteProduct → success: $id');
  }

  // ─── Clear Group Cache ────────────────────────────────────────────────────

  @override
  void clearCache() async {
    _groupCache = {};
    _cachedProducts = null;
    _lastFetchTime = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sapProductsCacheKey);
    await prefs.remove(_sapLastFetchKey);
    // Note: we might want to keep _uploadedImages or clear them too.
    // Given the request, "next day they fetch again", clearing images on logout is safer.
    await prefs.remove(_sapUploadedImagesKey);
    _uploadedImages.clear();

    debugPrint('SapProductDataSource → Cache and persistence cleared.');
  }

  // ─── Parse SAP Error Response ─────────────────────────────────────────────

  String _parseError(String body) {
    try {
      final json = jsonDecode(body);
      return json['error']['message']['value'] ?? body;
    } catch (_) {
      return body;
    }
  }
}