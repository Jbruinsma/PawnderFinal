class Community {
  const Community({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}
