class StudyGroup {
  final String id;
  final String campusId;
  final String creatorId;
  final String creatorName;
  final String subject;
  final String description;
  final String dateTime;
  final String location;
  final int memberCount;
  final int maxMembers;
  final DateTime createdAt;

  StudyGroup({
    required this.id,
    required this.campusId,
    required this.creatorId,
    required this.creatorName,
    required this.subject,
    required this.description,
    required this.dateTime,
    required this.location,
    required this.memberCount,
    required this.maxMembers,
    required this.createdAt,
  });

  factory StudyGroup.fromJson(Map<String, dynamic> json) {
    return StudyGroup(
      id: json['id']?.toString() ?? '',
      campusId: json['campus_id']?.toString() ?? '',
      creatorId: json['creator_id']?.toString() ?? '',
      creatorName: json['creator_name']?.toString() ?? 'Unknown',
      subject: json['subject']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      dateTime: json['date_time']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      memberCount: json['member_count'] as int? ?? 0,
      maxMembers: json['max_members'] as int? ?? 5,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toUtc()
          : DateTime.now().toUtc(),
    );
  }
}
