import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/campus_provider.dart';

/// Fetches live Lost/Found + Communities from Supabase and merges cached Notes/Events
/// from Riverpod streams. Inject the returned string into the AI system context before
/// answering (e.g. “did anyone report a lost iPhone?”).
Future<String> loadAiPromptContext(WidgetRef ref) async {
  final client = Supabase.instance.client;
  final campusId = ref.read(selectedCampusIdProvider);
  final buffer = StringBuffer();

  buffer.writeln(
    'Context — treat this as authoritative campus data when it matches the user question:',
  );

  try {
    if (campusId != null) {
      final comms = await client
          .from('communities')
          .select('name,is_private,description')
          .eq('campus_id', campusId)
          .limit(40);
      final list = comms as List;
      if (list.isEmpty) {
        buffer.writeln('Communities on this campus: (none listed yet).');
      } else {
        final parts = list.map<String>((c) {
          final m = Map<String, dynamic>.from(c as Map);
          final name = m['name']?.toString() ?? 'Unnamed';
          final priv = m['is_private'] == true;
          final desc = (m['description']?.toString() ?? '').trim();
          final short =
              desc.length > 100 ? '${desc.substring(0, 100)}…' : desc;
          return '$name${priv ? ' [private]' : ' [public]'}'
              '${short.isEmpty ? '' : ' — $short'}';
        });
        buffer.writeln('Communities: ${parts.join(' | ')}');
      }
    } else {
      buffer.writeln('Communities: (no campus selected in the app).');
    }
  } catch (e) {
    buffer.writeln('Communities: (could not load: $e)');
  }

  try {
    final lost = await client
        .from('lost_found')
        .select()
        .order('created_at', ascending: false)
        .limit(45);
    final rows = lost as List;
    if (rows.isEmpty) {
      buffer.writeln('Lost & Found: (no reports in database).');
    } else {
      buffer.writeln('Lost & Found reports (newest first):');
      for (final raw in rows) {
        final r = Map<String, dynamic>.from(raw as Map);
        final title = (r['title'] ?? r['name'] ?? 'item').toString();
        final desc = (r['description'] ?? '').toString().replaceAll('\n', ' ');
        final typ = (r['type'] ?? 'lost').toString();
        final loc = (r['location'] ?? '').toString();
        final st = (r['status'] ?? '').toString();
        buffer.writeln(
          '- [$typ] $title; details: $desc; where: $loc; status: $st',
        );
      }
    }
  } catch (e) {
    buffer.writeln('Lost & Found: (could not load: $e)');
  }

  final notes = ref.read(academicNotesProvider).value ?? [];
  if (notes.isNotEmpty) {
    buffer.writeln(
      'Recent note titles: ${notes.take(15).map((n) => n.title).join('; ')}',
    );
  }

  final events = ref.read(campusEventsProvider).value ?? [];
  if (events.isNotEmpty) {
    buffer.writeln(
      'Campus events: ${events.take(12).map((e) => '${e.title} (${e.dateTime})').join('; ')}',
    );
  }

  buffer.writeln(
    'Answer the user. If they ask about a lost phone or item, compare their wording to the Lost & Found lines. If nothing matches, say so clearly.',
  );

  return buffer.toString().trim();
}
