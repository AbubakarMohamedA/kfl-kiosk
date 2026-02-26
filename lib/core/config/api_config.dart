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
    var formattedUrl = url.trim();
    
    // Auto-prepend http:// if scheme missing
    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      formattedUrl = 'http://$formattedUrl';
    }
    
    // Auto-append :8080 if port missing
    try {
      var uri = Uri.parse(formattedUrl);
      if (!uri.hasPort) {
        uri = uri.replace(port: 8080);
        formattedUrl = uri.toString();
      }
    } catch (e) {
      // Fallback if parsing fails for some reason
    }
    
    _baseUrl = formattedUrl;
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
  
  // SAP Integration
  static String get sapBaseUrl => _baseUrl; // Can be overridden if SAP is on a different server
  static String get sapProductsEndpoint => '$sapBaseUrl/sap/products';
  
  // Image Upload
  static String get uploadEndpoint => '$_baseUrl/upload';
}
