import 'package:equatable/equatable.dart';

class Warehouse extends Equatable {
  final String id;
  final String tenantId;
  final String branchId;
  final String name;
  final List<String> categories; // e.g. ['Flour', 'Oil']
  final String loginUsername;
  final String loginPassword;
  final bool isActive;

  const Warehouse({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.name,
    required this.categories,
    required this.loginUsername,
    required this.loginPassword,
    this.isActive = true,
  });

  Warehouse copyWith({
    String? id,
    String? tenantId,
    String? branchId,
    String? name,
    List<String>? categories,
    String? loginUsername,
    String? loginPassword,
    bool? isActive,
  }) {
    return Warehouse(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      name: name ?? this.name,
      categories: categories ?? this.categories,
      loginUsername: loginUsername ?? this.loginUsername,
      loginPassword: loginPassword ?? this.loginPassword,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tenantId,
        branchId,
        name,
        categories,
        loginUsername,
        loginPassword,
        isActive,
      ];
}
