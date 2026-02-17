import 'package:equatable/equatable.dart';

class Tier extends Equatable {
  final String id;
  final String name;
  final List<String> enabledFeatures;
  final bool allowUpdates;
  final bool immuneToBlocking;
  final String description;

  const Tier({
    required this.id,
    required this.name,
    this.enabledFeatures = const [],
    this.allowUpdates = true,
    this.immuneToBlocking = false,
    this.description = '',
  });

  Tier copyWith({
    String? id,
    String? name,
    List<String>? enabledFeatures,
    bool? allowUpdates,
    bool? immuneToBlocking,
    String? description,
  }) {
    return Tier(
      id: id ?? this.id,
      name: name ?? this.name,
      enabledFeatures: enabledFeatures ?? this.enabledFeatures,
      allowUpdates: allowUpdates ?? this.allowUpdates,
      immuneToBlocking: immuneToBlocking ?? this.immuneToBlocking,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        enabledFeatures,
        allowUpdates,
        immuneToBlocking,
        description,
      ];
}
