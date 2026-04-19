import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bottom sheet partilhado: emojis sem overflow (scroll horizontal + escala + largura máxima).
class MessageInteractionSheet {
  MessageInteractionSheet._();

  static const List<String> defaultEmojis = [
    '❤️',
    '👍',
    '😂',
    '🔥',
    '😮',
    '😢',
    '🙏',
    '✨',
  ];

  /// ~20% menor que antes (26 → ~21).
  static const double _emojiFontSize = 21;

  static Future<void> show(
    BuildContext context, {
    String title = 'Message',
    required void Function(String emoji) onEmoji,
    VoidCallback? onReply,
    VoidCallback? onDelete,
    VoidCallback? onReport,
    VoidCallback? onPin,
    bool canDelete = false,
    bool canReport = false,
    bool canPin = false,
    String pinLabel = 'Pin',
  }) async {
    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) {
        final screenW = MediaQuery.sizeOf(ctx).width;
        final sheetMaxW = screenW * 0.8;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(ctx).bottom + 8,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: sheetMaxW),
                child: Material(
                  color: theme.colorScheme.surface,
                  elevation: 8,
                  shadowColor: Colors.black26,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: theme.dividerColor.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: SizedBox(
                            width: sheetMaxW,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: defaultEmojis.map((emoji) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Transform.scale(
                                      scale: 0.8,
                                      child: Material(
                                        color: theme
                                            .colorScheme.primaryContainer
                                            .withValues(alpha: 0.35),
                                        shape: const CircleBorder(),
                                        child: InkWell(
                                          customBorder: const CircleBorder(),
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            Navigator.pop(ctx);
                                            onEmoji(emoji);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Text(
                                              emoji,
                                              style: TextStyle(
                                                fontSize: _emojiFontSize,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        if (onReply != null)
                          ListTile(
                            leading: Icon(
                              Icons.reply_rounded,
                              color: theme.colorScheme.primary,
                            ),
                            title: const Text('Reply'),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(ctx);
                              onReply();
                            },
                          ),
                        if (canDelete && onDelete != null)
                          ListTile(
                            leading: Icon(
                              Icons.delete_outline_rounded,
                              color: theme.colorScheme.error,
                            ),
                            title: Text(
                              'Delete',
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              Navigator.pop(ctx);
                              onDelete();
                            },
                          ),
                        if (canReport && onReport != null)
                          ListTile(
                            leading: Icon(
                              Icons.flag_outlined,
                              color: theme.colorScheme.tertiary,
                            ),
                            title: const Text('Report'),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(ctx);
                              onReport();
                            },
                          ),
                        if (canPin && onPin != null)
                          ListTile(
                            leading: Icon(
                              Icons.push_pin_outlined,
                              color: theme.colorScheme.secondary,
                            ),
                            title: Text(pinLabel),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(ctx);
                              onPin();
                            },
                          ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
