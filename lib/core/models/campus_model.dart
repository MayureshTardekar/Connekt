class Campus {
  final String id;
  final String name;
  final String? createdBy;
  final DateTime createdAt;

  Campus({
    required this.id,
    required this.name,
    this.createdBy,
    required this.createdAt,
  });

  factory Campus.fromJson(Map<String, dynamic> json) {
    return Campus(
      id: json['id'],
      name: json['name'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
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

  CampusMember({
    required this.id,
    required this.campusId,
    required this.userId,
    this.uid,
    this.course,
    this.branch,
    required this.role,
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
    );
  }
}
