import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps a chat bubble: swipe to reply, long-press for the action sheet.
/// Use in Ghost, Community, and Study Groups for consistent behavior.
class BaseChatMessageShell extends StatelessWidget {
  const BaseChatMessageShell({
    super.key,
    required this.messageKey,
    required this.onSwipeReply,
    required this.onLongPress,
    required this.child,
    this.maxWidthFactor = 0.78,
    this.dismissDirection = DismissDirection.startToEnd,
    this.swipeBackground,
  });

  final Key messageKey;
  final VoidCallback onSwipeReply;
  final VoidCallback onLongPress;
  final Widget child;
  final double maxWidthFactor;
  final DismissDirection dismissDirection;
  final Widget? swipeBackground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxW = MediaQuery.sizeOf(context).width * maxWidthFactor;

    final swipeChild =
        swipeBackground ??
        Icon(Icons.reply_rounded, color: theme.colorScheme.primary);

    return Dismissible(
      key: messageKey,
      direction: dismissDirection,
      confirmDismiss: (_) async {
        HapticFeedback.lightImpact();
        onSwipeReply();
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 12),
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        child: swipeChild,
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 12),
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        child: swipeChild,
      ),
      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.mediumImpact();
          onLongPress();
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: child,
        ),
      ),
    );
  }
}
