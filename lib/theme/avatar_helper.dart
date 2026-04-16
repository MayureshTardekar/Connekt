import 'package:flutter/material.dart';

/// Generates a consistent color from a name string
Color avatarColor(String name) {
  final colors = [
    const Color(0xFF4F46E5), // Indigo
    const Color(0xFF7C3AED), // Purple
    const Color(0xFF0D9488), // Teal
    const Color(0xFFF43F5E), // Rose
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF10B981), // Emerald
    const Color(0xFF3B82F6), // Blue
    const Color(0xFFE11D48), // Red
    const Color(0xFF8B5CF6), // Violet
    const Color(0xFF06B6D4), // Cyan
  ];
  final index =
      name.codeUnits.fold<int>(0, (prev, c) => prev + c) % colors.length;
  return colors[index];
}

/// Returns 1-2 character initials from a name
String initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return name.isNotEmpty ? name[0].toUpperCase() : '?';
}

/// Builds a CircleAvatar with colored initials or network image
Widget avatarWidget(String name, {double radius = 22, String? imageUrl, String? pictureUrl}) {
  final initialsWidget = CircleAvatar(
    radius: radius,
    backgroundColor: avatarColor(name),
    child: Text(
      initials(name),
      style: TextStyle(
        color: Colors.white,
        fontSize: radius * 0.7,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  final effectiveUrl = (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : pictureUrl;

  if (effectiveUrl != null && effectiveUrl.isNotEmpty) {
    return ClipOval(
      child: Image.network(
        effectiveUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // If 429 or any error happens, fall back to initials
          return initialsWidget;
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return initialsWidget; // Show initials while loading
        },
      ),
    );
  }
  return initialsWidget;
}

/// Placeholder for image cards — gradient with icon
Widget imagePlaceholder({
  double height = 150,
  IconData icon = Icons.image_rounded,
  List<Color>? colors,
}) {
  return Container(
    height: height,
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: colors ?? const [Color(0xFF1E293B), Color(0xFF334155)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(child: Icon(icon, size: 40, color: Colors.white24)),
  );
}
