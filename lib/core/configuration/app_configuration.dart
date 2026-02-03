enum StatusTrackingMode {
  orderLevel,   // Traditional: entire order has single status
  itemLevel,    // Advanced: per-item/warehouse status tracking
}

class AppConfiguration {
  final StatusTrackingMode statusTrackingMode;
  final bool darkMode;
  final String language;
  // Add other config options here

  AppConfiguration({
    this.statusTrackingMode = StatusTrackingMode.orderLevel, // Default to advanced mode
    this.darkMode = false,
    this.language = 'en',
  });

  AppConfiguration copyWith({
    StatusTrackingMode? statusTrackingMode,
    bool? darkMode,
    String? language,
  }) {
    return AppConfiguration(
      statusTrackingMode: statusTrackingMode ?? this.statusTrackingMode,
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() => {
        'statusTrackingMode': statusTrackingMode.index,
        'darkMode': darkMode,
        'language': language,
      };

  factory AppConfiguration.fromJson(Map<String, dynamic> json) {
    return AppConfiguration(
      statusTrackingMode: StatusTrackingMode.values[
          json['statusTrackingMode'] ?? StatusTrackingMode.itemLevel.index],
      darkMode: json['darkMode'] ?? false,
      language: json['language'] ?? 'en',
    );
  }
}