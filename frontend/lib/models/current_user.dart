class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.role,
    required this.email,
    required this.fullName,
    required this.createdAt,
  });

  final String id;
  final String role;
  final String email;
  final String fullName;
  final DateTime createdAt;

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    return CurrentUser(
      id: json['id'].toString(),
      role: json['role']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }
}
