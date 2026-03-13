import 'package:equatable/equatable.dart';

class TerminalInfo extends Equatable {
  final String id;
  final String tenantId;
  final String flavor;
  final String platform;
  final String version;
  final DateTime lastSeen;
  final String? deviceName;
  final String? publicIp;

  const TerminalInfo({
    required this.id,
    required this.tenantId,
    required this.flavor,
    required this.platform,
    required this.version,
    required this.lastSeen,
    this.deviceName,
    this.publicIp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'flavor': flavor,
      'platform': platform,
      'version': version,
      'lastSeen': lastSeen.toIso8601String(),
      'deviceName': deviceName,
      'publicIp': publicIp,
    };
  }

  factory TerminalInfo.fromJson(Map<String, dynamic> json) {
    return TerminalInfo(
      id: json['id'] ?? '',
      tenantId: json['tenantId'] ?? '',
      flavor: json['flavor'] ?? '',
      platform: json['platform'] ?? '',
      version: json['version'] ?? '',
      lastSeen: json['lastSeen'] != null 
          ? DateTime.parse(json['lastSeen']) 
          : DateTime.now(),
      deviceName: json['deviceName'],
      publicIp: json['publicIp'],
    );
  }

  TerminalInfo copyWith({
    String? id,
    String? tenantId,
    String? flavor,
    String? platform,
    String? version,
    DateTime? lastSeen,
    String? deviceName,
    String? publicIp,
  }) {
    return TerminalInfo(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      flavor: flavor ?? this.flavor,
      platform: platform ?? this.platform,
      version: version ?? this.version,
      lastSeen: lastSeen ?? this.lastSeen,
      deviceName: deviceName ?? this.deviceName,
      publicIp: publicIp ?? this.publicIp,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tenantId,
        flavor,
        platform,
        version,
        lastSeen,
        deviceName,
        publicIp,
      ];
}
