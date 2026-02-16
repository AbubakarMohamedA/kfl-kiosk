import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String username;
  final String role;
  final String? token;

  const User({
    required this.id,
    required this.username,
    required this.role,
    this.token,
  });

  @override
  List<Object?> get props => [id, username, role, token];
}
