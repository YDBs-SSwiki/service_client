// lib/models/user.dart

class UserInfo {
  final int userId;
  final String username;
  final String role;
  final String? emailAddress;
  final String? createdAt;
  final String? lastModifiedAt;

  UserInfo({
    required this.userId,
    required this.username,
    required this.role,
    this.emailAddress,
    this.createdAt,
    this.lastModifiedAt,
  });

  factory UserInfo.fromJson(Map<String, dynamic> j) {
    return UserInfo(
      userId: j['userId'],
      username: j['username'] ?? '(알수없음)',
      role: j['role'] ?? 'USER',
      emailAddress: j['emailAddress'],
      createdAt: j['createdAt'],
      lastModifiedAt: j['lastModifiedAt'],
    );
  }
}
