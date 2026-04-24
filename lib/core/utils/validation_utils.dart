import 'package:flutter/foundation.dart';

class ValidationUtils {
  /// Regular expression for a standard UUID v4.
  static final RegExp uuidRegExp = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// Check if a string is a valid UUID.
  static bool isValidUuid(String? id) {
    if (id == null || id.isEmpty) return false;
    // Some versions of UUID might not be exactly v4, so a more permissive check:
    final permissiveRegExp = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return permissiveRegExp.hasMatch(id);
  }

  /// Clean an ID if it's accidentally prefixed (like by some mock data generators).
  static String? sanitizeUuid(String? id) {
    if (id == null) return null;

    // Trim whitespace first to handle any accidental padding
    var cleanId = id.trim();

    // Remove leading underscore if present (known mock-data artifact)
    if (cleanId.startsWith('_')) {
      cleanId = cleanId.substring(1);
    }

    if (isValidUuid(cleanId)) {
      return cleanId;
    }
    return null;
  }
}
