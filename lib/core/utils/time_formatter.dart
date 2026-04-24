class TimeFormatter {
  /// Formats a [DateTime] (or ISO-8601 [String]) into a relative time string.
  /// Always normalises to UTC before computing the difference, so UTC timestamps
  /// from Supabase are displayed correctly regardless of the device's local timezone.
  static String format(dynamic input) {
    DateTime? dateTime;

    if (input is DateTime) {
      dateTime = input;
    } else if (input is String) {
      dateTime = DateTime.tryParse(input);
    }

    if (dateTime == null) return '';

    // CRITICAL: Always work in UTC so that IST (+5:30) or any other offset
    // does not skew the difference calculation.
    final utcNow = DateTime.now().toUtc();
    final utcTime = dateTime.toUtc();
    final difference = utcNow.difference(utcTime);

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
