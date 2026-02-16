enum StatusTrackingMode {
  orderLevel,   // Traditional: entire order has single status
  itemLevel,    // Advanced: per-item/warehouse status tracking
}

class AppConfiguration {
  // Existing configuration options
  final StatusTrackingMode statusTrackingMode;
  final bool darkMode;
  final String language;
  
  // Tenant configuration fields
  final bool isConfigured;           // Whether initial setup has been completed
  final String? tenantId;            // Unique tenant identifier
  final String? businessName;        // Business/company name
  final String? contactEmail;        // Contact email
  final String? contactPhone;        // Contact phone
  final String? businessAddress;     // Business address
  final String? logoPath;            // Path to uploaded logo (optional)
  final String? defaultWarehouse;    // Default warehouse for this tenant
  final String currency;             // Currency code (e.g., "KSH")
  final bool enableNotifications;    // Push notifications enabled

  AppConfiguration({
    this.statusTrackingMode = StatusTrackingMode.orderLevel,
    this.darkMode = false,
    this.language = 'en',
    // Tenant configuration defaults
    this.isConfigured = false,
    this.tenantId,
    this.businessName,
    this.contactEmail,
    this.contactPhone,
    this.businessAddress,
    this.logoPath,
    this.defaultWarehouse,
    this.currency = 'KSH',
    this.enableNotifications = true,
  });

  AppConfiguration copyWith({
    StatusTrackingMode? statusTrackingMode,
    bool? darkMode,
    String? language,
    bool? isConfigured,
    String? tenantId,
    String? businessName,
    String? contactEmail,
    String? contactPhone,
    String? businessAddress,
    String? logoPath,
    String? defaultWarehouse,
    String? currency,
    bool? enableNotifications,
  }) {
    return AppConfiguration(
      statusTrackingMode: statusTrackingMode ?? this.statusTrackingMode,
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
      isConfigured: isConfigured ?? this.isConfigured,
      tenantId: tenantId ?? this.tenantId,
      businessName: businessName ?? this.businessName,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      businessAddress: businessAddress ?? this.businessAddress,
      logoPath: logoPath ?? this.logoPath,
      defaultWarehouse: defaultWarehouse ?? this.defaultWarehouse,
      currency: currency ?? this.currency,
      enableNotifications: enableNotifications ?? this.enableNotifications,
    );
  }

  Map<String, dynamic> toJson() => {
    'statusTrackingMode': statusTrackingMode.index,
    'darkMode': darkMode,
    'language': language,
    'isConfigured': isConfigured,
    'tenantId': tenantId,
    'businessName': businessName,
    'contactEmail': contactEmail,
    'contactPhone': contactPhone,
    'businessAddress': businessAddress,
    'logoPath': logoPath,
    'defaultWarehouse': defaultWarehouse,
    'currency': currency,
    'enableNotifications': enableNotifications,
  };

  factory AppConfiguration.fromJson(Map<String, dynamic> json) {
    return AppConfiguration(
      statusTrackingMode: StatusTrackingMode.values[
          json['statusTrackingMode'] ?? StatusTrackingMode.orderLevel.index],
      darkMode: json['darkMode'] ?? false,
      language: json['language'] ?? 'en',
      isConfigured: json['isConfigured'] ?? false,
      tenantId: json['tenantId'],
      businessName: json['businessName'],
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      businessAddress: json['businessAddress'],
      logoPath: json['logoPath'],
      defaultWarehouse: json['defaultWarehouse'],
      currency: json['currency'] ?? 'KSH',
      enableNotifications: json['enableNotifications'] ?? true,
    );
  }
}