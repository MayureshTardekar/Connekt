import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/campus_model.dart';

class CampusRepository {
  final _supabase = Supabase.instance.client;

  // Fetch all available campuses
  Future<List<Campus>> getAllCampuses() async {
    final response = await _supabase
        .from('campuses')
        .select()
        .order('name');
    
    return (response as List).map((json) => Campus.fromJson(json)).toList();
  }

  // Check how many campuses user has joined
  Future<int> getJoinedCampusCount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 0;

    final response = await _supabase
        .from('campus_members')
        .select('id')
        .eq('user_id', user.id);
    
    return (response as List).length;
  }

  Future<Campus> createCampus(String name) async {
    final user = _supabase.auth.currentUser;
    
    // Check if name already exists (Case insensitive check would be better but simple eq for now)
    final existing = await _supabase
        .from('campuses')
        .select()
        .eq('name', name)
        .maybeSingle();
    
    if (existing != null) {
      throw Exception('A campus with this name already exists. Please join it instead!');
    }

    final response = await _supabase.from('campuses').insert({
      'name': name,
      'created_by': user?.id,
    }).select().single();

    return Campus.fromJson(response);
  }

  // Join a campus with details
  Future<void> joinCampus({
    required String campusId,
    required String uid,
    required String course,
    required String branch,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // 1. Check if already joined this specific campus
    final existingMembership = await _supabase
        .from('campus_members')
        .select()
        .eq('user_id', user.id)
        .eq('campus_id', campusId)
        .maybeSingle();
    
    // If already a member, just return (UI will redirect)
    if (existingMembership != null) return;

    // 2. Check total joined count
    final count = await getJoinedCampusCount();
    if (count >= 3) {
      throw Exception('Limit reached: You can join at most 3 campuses');
    }

    // 3. New join
    await _supabase.from('campus_members').insert({
      'campus_id': campusId,
      'user_id': user.id,
      'uid': uid,
      'course': course,
      'branch': branch,
    });
  }

  // Get user's joined campuses
  Future<List<Map<String, dynamic>>> getMyCampuses() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('campus_members')
        .select('*, campuses(*)')
        .eq('user_id', user.id);
    
    return response;
  }

  Future<List<Map<String, dynamic>>> getMyMemberships() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('campus_members')
        .select('*, campuses(name)')
        .eq('user_id', user.id);
    
    return response;
  }

  // Real-time events stream
  Stream<List<Map<String, dynamic>>> watchEvents() {
    return _supabase
        .from('campus_events')
        .stream(primaryKey: ['id'])
        .order('date_time', ascending: true);
  }

  // Real-time lost & found stream
  Stream<List<Map<String, dynamic>>> watchLostFoundItems() {
    return _supabase
        .from('lost_found')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  // Notes stream
  Stream<List<Map<String, dynamic>>> watchNotes() {
    return _supabase
        .from('academic_notes')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  // Check if user is a member of any campus
  Future<bool> isMemberOfAnyCampus() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;
    
    final response = await _supabase
        .from('campus_members')
        .select('id')
        .eq('user_id', user.id)
        .limit(1);
    
    return (response as List).isNotEmpty;
  }

  // Combined Recent Activity Stream for Dashboard
  Stream<List<Map<String, dynamic>>> getRecentActivityStream() {
    // For Dashboard Recent Activity, we combine multiple sources
    // Note: In production, a database view is better, but this works for development.
    return _supabase
        .from('academic_notes')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(10)
        .asyncMap((notes) async {
          final List<Map<String, dynamic>> activities = [];
          
          // Process Notes
          for (var n in notes) {
            activities.add({
              'type': 'note',
              'title': n['title'],
              'subtitle': 'New study note in ${n['category']}',
              'created_at': DateTime.parse(n['created_at']),
              'icon': 'description',
            });
          }

          // Fetch some events to mix in (manual fetch as stream combine is complex)
          try {
            final events = await _supabase.from('campus_events').select().limit(2);
            for (var e in events) {
              activities.add({
                'type': 'event',
                'title': e['title'],
                'subtitle': 'Join this event! 🎉',
                'created_at': DateTime.parse(e['date_time']),
                'icon': 'celebration',
              });
            }
          } catch (_) {}

          // Sort final list
          activities.sort((a, b) => (b['created_at'] as DateTime).compareTo(a['created_at'] as DateTime));
          return activities.take(10).toList();
        });
  }

  // Upload academic note
  Future<void> uploadNote({
    required String title,
    required String subject,
    required String description,
    required String fileName,
    required List<int> fileBytes,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // 1. Upload file to storage
    final storagePath = 'notes/${user.id}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    
    await _supabase.storage.from('academic_resources').uploadBinary(
      storagePath,
      fileBytes as dynamic,
      fileOptions: const FileOptions(contentType: 'application/pdf'),
    );

    final fileUrl = _supabase.storage.from('academic_resources').getPublicUrl(storagePath);

    // 2. Insert record
    await _supabase.from('academic_notes').insert({
      'title': title,
      'category': subject,
      'description': description,
      'file_url': fileUrl,
      'author': user.email?.split('@')[0] ?? 'Student',
      'pages': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Create campus event
  Future<void> createEvent({
    required String title,
    required String description,
    required String location,
    required DateTime dateTime,
    required String category,
    String? imageUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _supabase.from('campus_events').insert({
      'title': title,
      'description': description,
      'location': location,
      'date_time': dateTime.toIso8601String(),
      'category': category,
      'organizer': user.email?.split('@')[0] ?? 'Student',
      'image_url': imageUrl,
      'attendees': 0,
    });
  }

  // Report lost/found item
  Future<void> reportLostFoundItem({
    required String title,
    required String description,
    required String location,
    required String type,
    String? imageUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _supabase.from('lost_found').insert({
      'title': title,
      'description': description,
      'location': location,
      'type': type,
      'status': 'Open',
      'image_url': imageUrl,
      'posted_by': user.id,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
