import 'package:flutter/material.dart';

/// Centers its [child] horizontally and caps it at [maxWidth].
///
/// Use it to wrap page bodies (forms, cards, lists) so content sits in a tidy
/// centered column on wide/desktop screens instead of stretching full-bleed or
/// clinging to one edge. On narrow screens it simply fills the width.
///
/// Compose it inside a scroll view's child, or use it directly as a page body.
class CenteredContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const CenteredContent({
    super.key,
    required this.child,
    this.maxWidth = 720,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
