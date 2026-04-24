class Community {
  const Community({
    required this.id,
    required this.name,
    required this.description,
    this.postCount = 0,
    this.memberCount = 0,
  });

  final String id;
  final String name;
  final String description;
  final int postCount;
  final int memberCount;

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      postCount: (json['post_count'] as num?)?.toInt() ?? 0,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
    );
  }
}
