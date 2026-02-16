import 'package:equatable/equatable.dart';

enum TenantTier { standard, premium }

class Tenant extends Equatable {
  final String id;
  final String name;
  final String businessName;
  final String email;
  final String phone;
  final String status; // 'Active', 'Inactive', 'Pending'
  final TenantTier tier; // 'Standard', 'Premium'
  final DateTime createdDate;
  final DateTime? lastLogin;
  final int ordersCount;
  final double revenue;
  final bool isMaintenanceMode;
  final List<String> enabledFeatures;

  const Tenant({
    required this.id,
    required this.name,
    required this.businessName,
    required this.email,
    required this.phone,
    required this.status,
    this.tier = TenantTier.standard,
    required this.createdDate,
    this.lastLogin,
    this.ordersCount = 0,
    this.revenue = 0.0,
    this.isMaintenanceMode = false,
    this.enabledFeatures = const [],
  });

  Tenant copyWith({
    String? id,
    String? name,
    String? businessName,
    String? email,
    String? phone,
    String? status,
    TenantTier? tier,
    DateTime? createdDate,
    DateTime? lastLogin,
    int? ordersCount,
    double? revenue,
    bool? isMaintenanceMode,
    List<String>? enabledFeatures,
  }) {
    return Tenant(
      id: id ?? this.id,
      name: name ?? this.name,
      businessName: businessName ?? this.businessName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      tier: tier ?? this.tier,
      createdDate: createdDate ?? this.createdDate,
      lastLogin: lastLogin ?? this.lastLogin,
      ordersCount: ordersCount ?? this.ordersCount,
      revenue: revenue ?? this.revenue,
      isMaintenanceMode: isMaintenanceMode ?? this.isMaintenanceMode,
      enabledFeatures: enabledFeatures ?? this.enabledFeatures,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        businessName,
        email,
        phone,
        status,
        tier,
        createdDate,
        lastLogin,
        ordersCount,
        revenue,
        isMaintenanceMode,
        enabledFeatures,
      ];
}
