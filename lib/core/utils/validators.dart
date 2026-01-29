class Validators {
  // Phone number validation for Kenyan numbers
  static bool isValidPhoneNumber(String phone) {
    if (phone.isEmpty) return false;
    
    // Remove spaces and dashes
    final cleaned = phone.replaceAll(RegExp(r'[\s-]'), '');
    
    // Check if it's a valid Kenyan number
    // Valid formats: 0712345678, 712345678, +254712345678, 254712345678
    final kenyanPhoneRegex = RegExp(r'^(?:\+?254|0)?[17]\d{8}$');
    
    return kenyanPhoneRegex.hasMatch(cleaned);
  }

  // Format phone number to standard format (0712345678)
  static String formatPhoneNumber(String phone) {
    if (!isValidPhoneNumber(phone)) return phone;
    
    final cleaned = phone.replaceAll(RegExp(r'[\s-]'), '');
    
    // Convert to 07XXXXXXXX format
    if (cleaned.startsWith('+254')) {
      return '0${cleaned.substring(4)}';
    } else if (cleaned.startsWith('254')) {
      return '0${cleaned.substring(3)}';
    } else if (cleaned.startsWith('7') || cleaned.startsWith('1')) {
      return '0$cleaned';
    }
    
    return cleaned;
  }

  // Validate order ID format
  static bool isValidOrderId(String orderId) {
    if (orderId.isEmpty) return false;
    
    // Format: ORD0001, ORD0002, etc.
    final orderIdRegex = RegExp(r'^ORD\d{4,}$');
    return orderIdRegex.hasMatch(orderId);
  }

  // Validate quantity
  static bool isValidQuantity(int quantity) {
    return quantity > 0 && quantity <= 1000; // Max 1000 items
  }

  // Validate price
  static bool isValidPrice(double price) {
    return price > 0 && price < 1000000; // Max price 1M
  }

  // Validate product ID
  static bool isValidProductId(String productId) {
    return productId.isNotEmpty && productId.length <= 100;
  }

  // Validate amount for payment
  static bool isValidPaymentAmount(double amount) {
    return amount >= 1 && amount <= 1000000; // Min 1 KSh, Max 1M KSh
  }

  // Sanitize string input
  static String sanitizeInput(String input) {
    return input.trim();
  }

  // Check if string is empty or whitespace
  static bool isEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }

  // Validate email (for future use)
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    return emailRegex.hasMatch(email);
  }

  // Validate string length
  static bool isValidLength(String value, {int min = 0, int max = 1000}) {
    final length = value.length;
    return length >= min && length <= max;
  }

  // Check if number is within range
  static bool isInRange(num value, {required num min, required num max}) {
    return value >= min && value <= max;
  }
}