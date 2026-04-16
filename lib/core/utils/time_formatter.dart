class TimeFormatter {
  static String format(DateTime dateTime) {
    final now = DateTime.now().toUtc();
    final difference = now.difference(dateTime.toUtc());

    if (difference.isNegative || difference.inHours < 1) {
      return 'just now';
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
