class AppConstants {
  // App Info
  static const String appName = 'KFM Self-Service Kiosk';
  static const String appVersion = '1.0.0';
  
  // Timing
  static const Duration idleTimeout = Duration(minutes: 2);
  static const Duration paymentProcessingDuration = Duration(seconds: 3);
  static const Duration receiptDisplayDuration = Duration(seconds: 15);
  
  // Order Status
  static const String statusPaid = 'PAID';
  static const String statusPreparing = 'PREPARING';
  static const String statusReadyForPickup = 'READY FOR PICKUP';
  static const String statusFulfilled = 'FULFILLED';
  
  // Language
  static const String languageEnglish = 'en';
  static const String languageSwahili = 'sw';
  
  // Responsive Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  static const double largeDesktopBreakpoint = 1800;
  
  // Storage Keys
  static const String keyOrders = 'orders';
  static const String keyOrderCounter = 'order_counter';
  static const String keyLanguagePreference = 'language_preference';
}

class AppColors {
  // Primary brand color - vibrant Salem green (#0B8843)
  static const int primaryBlue = 0xFF0B8843;

  // Secondary brand color - deep Jewel green (#0A5730)
  static const int secondaryGold = 0xFF0A5730;

  // Light accent color - Moss Green (#C7E2B2)
  static const int lightBlue = 0xFFC7E2B2;
}

class AppStrings {
  // English
  static const Map<String, String> en = {
    'welcome': 'Welcome to',
    'company_name': 'Kitui Flour Mills',
    'self_service': 'Self-Service Shop',
    'start_order': 'Start Order',
    'select_items': 'Select Items',
    'your_cart': 'Your Cart',
    'cart_empty': 'Cart is empty',
    'add_to_cart': 'Add to Cart',
    'total': 'Total',
    'checkout': 'Checkout →',
    'proceed_to_payment': 'Proceed to Payment →',
    'payment': 'Payment',
    'enter_mpesa': 'Enter M-Pesa Phone Number',
    'waiting_confirmation': 'Waiting for M-Pesa confirmation...',
    'check_phone': 'Check your phone to complete payment',
    'payment_success': 'Payment Successful!',
    'payment_failed': 'Payment Failed',
    'try_again': 'Try Again',
    'order_preparing': 'Your order is being prepared',
    'show_order_id': 'Show Order ID',
    'at_pickup': 'at pickup counter',
    'added_to_cart': 'Added to cart',
    'confirm_order': 'Confirm Your Order',
    'review_order_message': 'Please review your order details and quantities before proceeding to payment.',
    'qty': 'Qty:',
    'modify_order': 'Modify Order',
    'confirm_and_pay': 'Confirm & Pay',
    'order_number': 'Order Number',
  };
  
  // Swahili
  static const Map<String, String> sw = {
    'welcome': 'Karibu',
    'company_name': 'Kitui Flour Mills',
    'self_service': 'Duka la Kujihudumia',
    'start_order': 'Anza Oda',
    'select_items': 'Chagua Bidhaa',
    'your_cart': 'Kikapu Chako',
    'cart_empty': 'Kikapu ni tupu',
    'add_to_cart': 'Ongeza',
    'total': 'Jumla',
    'checkout': 'Lipa →',
    'proceed_to_payment': 'Endelea Kulipa →',
    'payment': 'Malipo',
    'enter_mpesa': 'Weka Namba ya M-Pesa',
    'waiting_confirmation': 'Inasubiri uthibitisho wa M-Pesa...',
    'check_phone': 'Angalia simu yako kukamilisha malipo',
    'payment_success': 'Malipo Yamefanikiwa!',
    'payment_failed': 'Malipo Yameshindwa',
    'try_again': 'Jaribu Tena',
    'order_preparing': 'Oda yako inaandaliwa',
    'show_order_id': 'Onyesha Namba ya Oda',
    'at_pickup': 'kwa kaunta',
    'added_to_cart': 'Imeongezwa kwenye kikapu',
    'confirm_order': 'Thibitisha Agizo Lako',
    'review_order_message': 'Tafadhali kagua maelezo ya agizo lako na idadi kabla ya kuendelea na malipo.',
    'qty': 'Idadi:',
    'modify_order': 'Badilisha Agizo',
    'confirm_and_pay': 'Thibitisha na Lipa',
    'order_number': 'Nambari ya Agizo',
  };
  
  static String get(String key, String language) {
    final map = language == AppConstants.languageSwahili ? sw : en;
    return map[key] ?? key;
  }
}