import 'package:equatable/equatable.dart';

class Branch extends Equatable {
  final String id;
  final String tenantId;
  final String name;
  final String location;
  final String contactPhone;
  final String managerName;
  final String loginUsername; // New: Unique username for branch manager
  final String loginPassword; // New: Password for branch manager
  final bool isActive;
  // Metrics (can be updated dynamically)
  final int totalOrders;
  final double revenue;

  // SAP Credentials Overrides
  final String? sapServerIp;
  final String? sapCompanyDb;
  final String? sapUsername;
  final String? sapPassword;

  const Branch({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.location,
    required this.contactPhone,
    required this.managerName,
    required this.loginUsername,
    required this.loginPassword,
    this.isActive = true,
    this.totalOrders = 0,
    this.revenue = 0.0,
    this.sapServerIp,
    this.sapCompanyDb,
    this.sapUsername,
    this.sapPassword,
  });

  Branch copyWith({
    String? id,
    String? tenantId,
    String? name,
    String? location,
    String? contactPhone,
    String? managerName,
    String? loginUsername,
    String? loginPassword,
    bool? isActive,
    int? totalOrders,
    double? revenue,
    String? sapServerIp,
    String? sapCompanyDb,
    String? sapUsername,
    String? sapPassword,
  }) {
    return Branch(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      location: location ?? this.location,
      contactPhone: contactPhone ?? this.contactPhone,
      managerName: managerName ?? this.managerName,
      loginUsername: loginUsername ?? this.loginUsername,
      loginPassword: loginPassword ?? this.loginPassword,
      isActive: isActive ?? this.isActive,
      totalOrders: totalOrders ?? this.totalOrders,
      revenue: revenue ?? this.revenue,
      sapServerIp: sapServerIp ?? this.sapServerIp,
      sapCompanyDb: sapCompanyDb ?? this.sapCompanyDb,
      sapUsername: sapUsername ?? this.sapUsername,
      sapPassword: sapPassword ?? this.sapPassword,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tenantId,
        name,
        location,
        contactPhone,
        managerName,
        loginUsername,
        loginPassword,
        isActive,
        totalOrders,
        revenue,
        sapServerIp,
        sapCompanyDb,
        sapUsername,
        sapPassword,
      ];
}
