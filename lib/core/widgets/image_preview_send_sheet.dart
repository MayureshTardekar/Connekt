import 'dart:typed_data';

import 'package:flutter/material.dart';

/// WhatsApp-style: preview + optional caption, then [onConfirm] (upload/send should happen here).
Future<void> showImagePreviewSendSheet({
  required BuildContext context,
  required Uint8List imageBytes,
  String fileExtension = 'jpg',
  String title = 'Send image',
  String captionLabel = 'Caption (optional)',
  String initialCaption = '',
  required Future<void> Function(
    Uint8List bytes,
    String extension,
    String caption,
  ) onConfirm,
}) async {
  final captionController = TextEditingController(text: initialCaption);
  final ext = fileExtension.isNotEmpty ? fileExtension.toLowerCase() : 'jpg';

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 340),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            imageBytes,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: captionController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: captionLabel,
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              final caption = captionController.text;
                              Navigator.pop(sheetContext);
                              await onConfirm(imageBytes, ext, caption);
                            },
                            child: const Text('Send'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  captionController.dispose();
}
