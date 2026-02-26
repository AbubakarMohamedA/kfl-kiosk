import 'package:equatable/equatable.dart';

enum LicenseStatus { active, expired, revoked }

class License extends Equatable {
  final String key;
  final String tenantId;
  final String generatedBy;
  final DateTime createdAt;
  final DateTime expiresAt;
  final LicenseStatus status;

  const License({
    required this.key,
    required this.tenantId,
    required this.generatedBy,
    required this.createdAt,
    required this.expiresAt,
    required this.status,
  });

  bool get isValid => 
      status == LicenseStatus.active && DateTime.now().isBefore(expiresAt);

  @override
  List<Object?> get props => [key, tenantId, generatedBy, createdAt, expiresAt, status];
}
