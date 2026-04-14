import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/campus_event.dart';
import '../models/lost_item.dart';
import '../network/logger.dart';

class CampusRepository {
  final _supabase = Supabase.instance.client;

  // --- Events ---
  Future<List<CampusEvent>> getEvents() async {
    try {
      final response = await _supabase
          .from('events')
          .select()
          .order('date_time', ascending: true);
      
      return (response as List).map((e) => CampusEvent.fromMap(e)).toList();
    } catch (e) {
      AppLogger.error('Error fetching events: $e');
      return [];
    }
  }

  Stream<List<CampusEvent>> watchEvents() {
    return _supabase
        .from('events')
        .stream(primaryKey: ['id'])
        .order('date_time', ascending: true)
        .map((data) => data.map((e) => CampusEvent.fromMap(e)).toList());
  }

  // --- Lost & Found ---
  Future<List<LostItem>> getLostFoundItems() async {
    try {
      final response = await _supabase
          .from('lost_found')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List).map((i) => LostItem.fromMap(i)).toList();
    } catch (e) {
      AppLogger.error('Error fetching lost/found: $e');
      return [];
    }
  }

  Stream<List<LostItem>> watchLostFoundItems() {
    return _supabase
        .from('lost_found')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((i) => LostItem.fromMap(i)).toList());
  }

  Future<void> reportLostItem(LostItem item) async {
    try {
      await _supabase.from('lost_found').insert(item.toMap());
    } catch (e) {
      AppLogger.error('Error reporting item: $e');
    }
  }
}
