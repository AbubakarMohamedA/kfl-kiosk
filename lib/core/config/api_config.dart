enum AppFlavor {
  mock,
  prod,
}

class ApiConfig {
  static AppFlavor _flavor = AppFlavor.mock;
  static String _baseUrl = 'http://localhost:8080';

  static void setFlavor(AppFlavor flavor) {
    _flavor = flavor;
  }

  static void setBaseUrl(String url) {
    _baseUrl = url;
    // Remove trailing slash if present
    if (_baseUrl.endsWith('/')) {
      _baseUrl = _baseUrl.substring(0, _baseUrl.length - 1);
    }
  }

  static bool get isMockMode => _flavor == AppFlavor.mock;
  static String get baseUrl => _baseUrl;
  
  // Feature specific endpoints
  static String get ordersEndpoint => '$_baseUrl/orders';
  static String get productsEndpoint => '$_baseUrl/products';
  static String get authEndpoint => '$_baseUrl/auth';
}
