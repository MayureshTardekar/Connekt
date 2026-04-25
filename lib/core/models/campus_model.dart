class Campus {
  final String id;
  final String name;
  final String? createdBy;
  final String? bannerUrl;
  final String? joinPin;
  final DateTime createdAt;

  Campus({
    required this.id,
    required this.name,
    this.createdBy,
    this.bannerUrl,
    this.joinPin,
    required this.createdAt,
  });

  factory Campus.fromJson(Map<String, dynamic> json) {
    return Campus(
      id: json['id'] as String,
      name: json['name'] as String,
      createdBy: json['created_by'] as String?,
      bannerUrl: json['banner_url'] as String?,
      // join_pin may not exist in the DB yet — read safely
      joinPin: json.containsKey('join_pin') ? json['join_pin'] as String? : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class CampusMember {
  final String id;
  final String campusId;
  final String userId;
  final String? uid;
  final String? course;
  final String? branch;
  final String role;
  final DateTime? createdAt;

  CampusMember({
    required this.id,
    required this.campusId,
    required this.userId,
    this.uid,
    this.course,
    this.branch,
    required this.role,
    this.createdAt,
  });

  factory CampusMember.fromJson(Map<String, dynamic> json) {
    return CampusMember(
      id: json['id'],
      campusId: json['campus_id'],
      userId: json['user_id'],
      uid: json['uid'],
      course: json['course'],
      branch: json['branch'],
      role: json['role'] ?? 'member',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }
}
