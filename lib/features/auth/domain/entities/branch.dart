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
      ];
}
