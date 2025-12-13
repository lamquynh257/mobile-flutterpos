class User {
  final int id;
  final String username;
  final String role;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.role,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      role: json['role'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
