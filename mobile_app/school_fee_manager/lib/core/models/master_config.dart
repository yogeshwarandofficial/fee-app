class MasterConfig {
  const MasterConfig({
    required this.id,
    required this.type,
    required this.name,
    this.parentId,
  });

  final String id;
  final String type;
  final String name;
  final String? parentId;

  factory MasterConfig.fromJson(Map<String, dynamic> json) {
    return MasterConfig(
      id: json['_id'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
      parentId: json['parent_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type,
      'name': name,
      'parent_id': parentId,
    };
  }
}
