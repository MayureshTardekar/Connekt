import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// WhatsApp-style image bubble: bounded box + [BoxFit.contain] for network (full photo visible).
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
            fit: BoxFit.contain,
            width: w,
            height: maxHeight,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => _errorBox(context),
          );
        } else {
          final url = networkUrl!.trim();
          image = CachedNetworkImage(
            imageUrl: url,
            width: w,
            height: maxHeight,
            fit: BoxFit.contain,
            fadeInDuration: const Duration(milliseconds: 150),
            memCacheWidth: (w * MediaQuery.devicePixelRatioOf(context)).round(),
            memCacheHeight: (maxHeight * MediaQuery.devicePixelRatioOf(context))
                .round(),
            progressIndicatorBuilder: (context, _, progress) {
              return SizedBox(
                width: w,
                height: maxHeight,
                child: Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: progress.progress,
                    ),
                  ),
                ),
              );
            },
            errorWidget: (context, _, __) => _errorBox(context),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: ColoredBox(
            color: Colors.black.withValues(alpha: 0.15),
            child: SizedBox(width: w, height: maxHeight, child: image),
          ),
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
