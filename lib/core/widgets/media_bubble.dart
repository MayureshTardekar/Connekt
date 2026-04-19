import 'dart:typed_data';

import 'package:flutter/material.dart';

/// WhatsApp-style image bubble: [ClipRRect] + [BoxFit.cover], bounded size.
/// Use [networkUrl] for remote images; [memoryBytes] for in-memory previews (all platforms).
/// Local file paths are not used here so the code stays web-safe (no `dart:io`).
class MediaBubble extends StatelessWidget {
  const MediaBubble({
    super.key,
    this.networkUrl,
    this.memoryBytes,
    this.maxWidth = 260,
    this.maxHeight = 260,
    this.borderRadius = 12,
  });

  final String? networkUrl;
  final Uint8List? memoryBytes;
  final double maxWidth;
  final double maxHeight;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final hasNet = networkUrl != null && networkUrl!.trim().isNotEmpty;
    final hasMem = memoryBytes != null && memoryBytes!.isNotEmpty;
    if (!hasNet && !hasMem) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final parentW = constraints.maxWidth;
        final w = parentW.isFinite && parentW > 0 && parentW < maxWidth
            ? parentW
            : maxWidth;

        Widget image;
        if (hasMem) {
          image = Image.memory(
            memoryBytes!,
            fit: BoxFit.cover,
            width: w,
            height: maxHeight,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => _errorBox(context),
          );
        } else {
          image = Image.network(
            networkUrl!.trim(),
            fit: BoxFit.cover,
            width: w,
            height: maxHeight,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => _errorBox(context),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              final total = loadingProgress.expectedTotalBytes;
              final value = total != null && total > 0
                  ? loadingProgress.cumulativeBytesLoaded / total
                  : null;
              return SizedBox(
                width: w,
                height: maxHeight,
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2, value: value),
                  ),
                ),
              );
            },
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: SizedBox(width: w, height: maxHeight, child: image),
        );
      },
    );
  }

  Widget _errorBox(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
