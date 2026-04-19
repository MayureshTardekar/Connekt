/// Supabase `jsonb` reaction maps: `{ "👍": ["uuid", ...], ... }`.
/// Never use `Map<String, List<String>>.from(raw)` — values are `List<dynamic>`.
Map<String, List<String>> parseReactionsJson(dynamic raw) {
  final out = <String, List<String>>{};
  if (raw == null) return out;
  if (raw is! Map) return out;
  final map = Map<Object?, Object?>.from(raw);
  for (final entry in map.entries) {
    final key = entry.key.toString();
    final v = entry.value;
    if (v is List) {
      out[key] = v.map((e) => e.toString()).toList();
    }
  }
  return out;
}

/// Payload safe for PostgREST JSONB update.
Map<String, dynamic> reactionsToJsonb(Map<String, List<String>> r) {
  return r.map((k, v) => MapEntry(k, v));
}
