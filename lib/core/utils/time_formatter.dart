class TimeFormatter {
  static final RegExp _timezoneSuffix = RegExp(r'(z|[+-]\d{2}:?\d{2})$', caseSensitive: false);

  /// Parses Supabase timestamps as UTC when the wire value omits an explicit
  /// timezone, then converts to device local time for UI display.
  static DateTime? parseSupabaseTimestamp(dynamic input) {
    if (input is DateTime) {
      return input.isUtc ? input.toLocal() : input;
    }
    if (input is! String || input.trim().isEmpty) return null;

    final raw = input.trim();
    final normalized = _timezoneSuffix.hasMatch(raw) ? raw : '${raw}Z';
    return DateTime.tryParse(normalized)?.toLocal();
  }

  /// Formats a [DateTime] (or ISO-8601 [String]) into a relative time string.
  /// Supabase UTC timestamps are converted to the device's local time before
  /// computing the relative label, avoiding timezone-offset drift.
  static String format(dynamic input) {
    final dateTime = parseSupabaseTimestamp(input);

    if (dateTime == null) return '';

    final difference = DateTime.now().difference(dateTime);

    if (difference.isNegative || difference.inSeconds < 45) {
      return 'just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d';
    }

    final weeks = (difference.inDays / 7).floor();
    return '${weeks}w';
  }
}
