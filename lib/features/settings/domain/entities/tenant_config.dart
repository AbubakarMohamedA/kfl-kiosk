import 'package:equatable/equatable.dart';

class TenantConfig extends Equatable {
  final String tenantId;
  final String? logoPath;
  final int? primaryColor;
  final int? secondaryColor;
  final String? backgroundPath;
  final String? appName; // Optional custom app name
  final String? welcomeMessage; // Optional custom welcome message

  const TenantConfig({
    required this.tenantId,
    this.logoPath,
    this.primaryColor,
    this.secondaryColor,
    this.backgroundPath,
    this.appName,
    this.welcomeMessage,
  });

  @override
  List<Object?> get props => [
        tenantId,
        logoPath,
        primaryColor,
        secondaryColor,
        backgroundPath,
        appName,
        welcomeMessage,
      ];
}
