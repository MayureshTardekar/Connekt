import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/academic_note.dart';

class NotesRepository {
  final _supabase = Supabase.instance.client;

  Future<List<AcademicNote>> getNotes() async {
    try {
      final response = await _supabase
          .from('notes')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List).map((note) => AcademicNote.fromMap(note)).toList();
    } catch (e) {
      print('Error fetching notes: $e');
      return [];
    }
  }

  Stream<List<AcademicNote>> watchNotes() {
    return _supabase
        .from('notes')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((note) => AcademicNote.fromMap(note)).toList());
  }

  Future<void> uploadNote(AcademicNote note) async {
    try {
      await _supabase.from('notes').insert(note.toMap());
    } catch (e) {
      print('Error uploading note: $e');
    }
  }
}
