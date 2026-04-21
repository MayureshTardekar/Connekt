import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Hero tag shared with the ghost chat image picker button for a WhatsApp-style flight.
const String kGhostImagePickerHeroTag = 'ghost-image-picker-hero';

/// Full-screen preview: optional caption, then [onConfirm]. Does not send automatically.
Future<void> openImagePreviewSendScreen({
  required BuildContext context,
  required Uint8List imageBytes,
  String fileExtension = 'jpg',
  String title = 'Send image',
  String captionLabel = 'Caption (optional)',
  String initialCaption = '',
  String heroTag = kGhostImagePickerHeroTag,
  required Future<void> Function(
    Uint8List bytes,
    String extension,
    String caption,
  ) onConfirm,
}) async {
  final ext = fileExtension.isNotEmpty ? fileExtension.toLowerCase() : 'jpg';

  await Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _ImagePreviewSendPage(
          imageBytes: imageBytes,
          fileExtension: ext,
          title: title,
          captionLabel: captionLabel,
          initialCaption: initialCaption,
          heroTag: heroTag,
          onConfirm: onConfirm,
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
        );
      },
    ),
  );
}

class _ImagePreviewSendPage extends StatefulWidget {
  const _ImagePreviewSendPage({
    required this.imageBytes,
    required this.fileExtension,
    required this.title,
    required this.captionLabel,
    required this.initialCaption,
    required this.heroTag,
    required this.onConfirm,
  });

  final Uint8List imageBytes;
  final String fileExtension;
  final String title;
  final String captionLabel;
  final String initialCaption;
  final String heroTag;
  final Future<void> Function(
    Uint8List bytes,
    String extension,
    String caption,
  ) onConfirm;

  @override
  State<_ImagePreviewSendPage> createState() => _ImagePreviewSendPageState();
}

class _ImagePreviewSendPageState extends State<_ImagePreviewSendPage> {
  late final TextEditingController _captionController;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.initialCaption);
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.94),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Hero(
                tag: widget.heroTag,
                flightShuttleBuilder: (
                  flightContext,
                  animation,
                  flightDirection,
                  fromHeroContext,
                  toHeroContext,
                ) {
                  final hero = flightDirection == HeroFlightDirection.push
                      ? toHeroContext.widget
                      : fromHeroContext.widget;
                  return hero;
                },
                child: Material(
                  color: Colors.transparent,
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: Image.memory(
                      widget.imageBytes,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.98),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _captionController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: widget.captionLabel,
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              final caption = _captionController.text;
                              Navigator.of(context).pop();
                              await widget.onConfirm(
                                widget.imageBytes,
                                widget.fileExtension,
                                caption,
                              );
                            },
                            child: const Text('Send'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
