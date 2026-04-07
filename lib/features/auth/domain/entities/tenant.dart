import 'package:equatable/equatable.dart';

class Tenant extends Equatable {
  final String id;
  final String name;
  final String businessName;
  final String email;
  final String phone;
  final String status; // 'Active', 'Inactive', 'Pending'
  final String tierId; // ID of the Tier entity
  final DateTime createdDate;
  final DateTime? lastLogin;
  final int ordersCount;
  final double revenue;
  final bool isMaintenanceMode; // Was missing
  final List<String> enabledFeatures; // Was missing
  final bool? allowUpdate; // Null = inherit from Tier
  final bool? immuneToBlocking; // Null = inherit from Tier

  // SAP Credentials
  final String? sapServerIp;
  final String? sapCompanyDb;
  final String? sapUsername;
  final String? sapPassword;

  const Tenant({
    required this.id,
    required this.name,
    required this.businessName,
    required this.email,
    required this.phone,
    required this.status,
    this.tierId = 'standard',
    required this.createdDate,
    this.lastLogin,
    this.ordersCount = 0,
    this.revenue = 0.0,
    this.isMaintenanceMode = false,
    this.enabledFeatures = const [],
    this.allowUpdate,
    this.immuneToBlocking,
    this.sapServerIp,
    this.sapCompanyDb,
    this.sapUsername,
    this.sapPassword,
  });

  Tenant copyWith({
    String? id,
    String? name,
    String? businessName,
    String? email,
    String? phone,
    String? status,
    String? tierId,
    DateTime? createdDate,
    DateTime? lastLogin,
    int? ordersCount,
    double? revenue,
    bool? isMaintenanceMode,
    List<String>? enabledFeatures,
    bool? allowUpdate, // Nullable to unset
    bool? immuneToBlocking, // Nullable to unset
    String? sapServerIp,
    String? sapCompanyDb,
    String? sapUsername,
    String? sapPassword,
  }) {
    return Tenant(
      id: id ?? this.id,
      name: name ?? this.name,
      businessName: businessName ?? this.businessName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      tierId: tierId ?? this.tierId,
      createdDate: createdDate ?? this.createdDate,
      lastLogin: lastLogin ?? this.lastLogin,
      ordersCount: ordersCount ?? this.ordersCount,
      revenue: revenue ?? this.revenue,
      isMaintenanceMode: isMaintenanceMode ?? this.isMaintenanceMode,
      enabledFeatures: enabledFeatures ?? this.enabledFeatures,
      allowUpdate: allowUpdate ?? this.allowUpdate,
      immuneToBlocking: immuneToBlocking ?? this.immuneToBlocking,
      sapServerIp: sapServerIp ?? this.sapServerIp,
      sapCompanyDb: sapCompanyDb ?? this.sapCompanyDb,
      sapUsername: sapUsername ?? this.sapUsername,
      sapPassword: sapPassword ?? this.sapPassword,
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
        tierId,
        createdDate,
        lastLogin,
        ordersCount,
        revenue,
        isMaintenanceMode,
        enabledFeatures,
        allowUpdate,
        immuneToBlocking,
        sapServerIp,
        sapCompanyDb,
        sapUsername,
        sapPassword,
      ];
}
