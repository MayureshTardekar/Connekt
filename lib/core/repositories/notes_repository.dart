import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/academic_note.dart';
import '../network/logger.dart';

class NotesRepository {
  SupabaseClient get _supabase => Supabase.instance.client;

  // Table name must match the Supabase schema: 'academic_notes'
  static const _table = 'academic_notes';

  Future<List<AcademicNote>> getNotes() async {
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((note) => AcademicNote.fromMap(note))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching notes: $e');
      rethrow;
    }
  }

  Stream<List<AcademicNote>> watchNotes() {
    return _supabase
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((note) => AcademicNote.fromMap(note)).toList());
  }

  Future<void> uploadNote(AcademicNote note) async {
    try {
      await _supabase.from(_table).insert(note.toMap());
    } catch (e) {
      AppLogger.error('Error uploading note: $e');
      rethrow;
    }
  }
}
