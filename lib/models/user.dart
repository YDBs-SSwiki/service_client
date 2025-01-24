// lib/models/user.dart
class User {
  final int userId;
  final String username;
  final String? emailAddress;
  final String role;

  User({
    required this.userId,
    required this.username,
    this.emailAddress,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
    userId: j['userId'],
    username: j['username'],
    emailAddress: j['emailAddress'],
    role: j['role'] ?? 'USER',
  );
}
