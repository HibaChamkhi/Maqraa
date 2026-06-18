import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Branded splash for وصال — deep green gradient, gold book emblem,
/// tagline and a faint mosque silhouette along the bottom.
class WesalSplash extends StatelessWidget {
  const WesalSplash({super.key, this.showLoader = true});

  /// Whether to render the small progress indicator (used while the
  /// first-boot auth check is still running).
  final bool showLoader;

  static const Color _gold = Color(0xFFE3B85C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.25),
            radius: 1.1,
            colors: [
              Color(0xFF1C7A52), // medium green (center glow)
              Color(0xFF115C3E),
              Color(0xFF0A3528), // dark green edges (vignette)
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Mosque silhouette pinned to the bottom.
            Align(
              alignment: Alignment.bottomCenter,
              child: CustomPaint(
                size: const Size(double.infinity, 180),
                painter: _MosquePainter(),
              ),
            ),
            // Brand block.
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BookEmblem(color: _gold),
                  const SizedBox(height: 28),
                  Text(
                    'وِصَال',
                    style: GoogleFonts.tajawal(
                      fontSize: 46,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'لحفظ القرآن الكريم',
                    style: GoogleFonts.tajawal(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                  if (showLoader) ...[
                    const SizedBox(height: 40),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gold open-book emblem inside a softly rounded frame.
class _BookEmblem extends StatelessWidget {
  const _BookEmblem({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      height: 116,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.6),
      ),
      child: CustomPaint(painter: _BookPainter(color)),
    );
  }
}

/// Draws a stylised open book with a small sprout/flame rising from it.
class _BookPainter extends CustomPainter {
  _BookPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Open book: two pages meeting at the spine.
    final bookTop = h * 0.56;
    final bookBottom = h * 0.74;
    final left = w * 0.22;
    final right = w * 0.78;

    final left2 = Path()
      ..moveTo(cx, bookTop)
      ..quadraticBezierTo(left + 6, bookTop - 6, left, bookTop)
      ..lineTo(left, bookBottom)
      ..quadraticBezierTo(left + 6, bookBottom - 6, cx, bookBottom + 2);
    final right2 = Path()
      ..moveTo(cx, bookTop)
      ..quadraticBezierTo(right - 6, bookTop - 6, right, bookTop)
      ..lineTo(right, bookBottom)
      ..quadraticBezierTo(right - 6, bookBottom - 6, cx, bookBottom + 2);
    canvas.drawPath(left2, stroke);
    canvas.drawPath(right2, stroke);
    // Spine.
    canvas.drawLine(Offset(cx, bookTop), Offset(cx, bookBottom + 2), stroke);

    // Sprout / flame rising above the book (knowledge & growth).
    final stemTop = h * 0.30;
    final stem = Path()
      ..moveTo(cx, bookTop)
      ..lineTo(cx, stemTop);
    canvas.drawPath(stem, stroke);

    final leaf = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    // Left leaf.
    final lp = Path()
      ..moveTo(cx, stemTop + h * 0.10)
      ..quadraticBezierTo(
          cx - w * 0.18, stemTop + h * 0.02, cx - w * 0.02, stemTop - h * 0.04)
      ..quadraticBezierTo(
          cx - w * 0.04, stemTop + h * 0.06, cx, stemTop + h * 0.10);
    // Right leaf.
    final rp = Path()
      ..moveTo(cx, stemTop + h * 0.10)
      ..quadraticBezierTo(
          cx + w * 0.18, stemTop + h * 0.02, cx + w * 0.02, stemTop - h * 0.04)
      ..quadraticBezierTo(
          cx + w * 0.04, stemTop + h * 0.06, cx, stemTop + h * 0.10);
    canvas.drawPath(lp, leaf);
    canvas.drawPath(rp, leaf);
  }

  @override
  bool shouldRepaint(covariant _BookPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Faint mosque skyline (domes + minarets) for the lower edge.
class _MosquePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0A3528).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final base = h; // ground line at the very bottom
    final path = Path()..moveTo(0, base);

    // Left minaret.
    _minaret(path, w * 0.16, base, h);
    // Main central dome.
    final domeBaseY = base - h * 0.30;
    path.lineTo(w * 0.34, domeBaseY);
    path.quadraticBezierTo(w * 0.36, base - h * 0.62, w * 0.40, base - h * 0.66);
    path.quadraticBezierTo(w * 0.50, base - h * 0.92, w * 0.60, base - h * 0.66);
    path.quadraticBezierTo(w * 0.64, base - h * 0.62, w * 0.66, domeBaseY);
    // Right minaret.
    _minaret(path, w * 0.84, base, h);
    path
      ..lineTo(w, base)
      ..close();
    canvas.drawPath(path, paint);

    // Spire tip on the central dome.
    final spire = Paint()
      ..color = const Color(0xFF0A3528).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawLine(
        Offset(w * 0.50, base - h * 0.92), Offset(w * 0.50, base - h * 1.02), spire);
  }

  void _minaret(Path path, double x, double base, double h) {
    final mw = h * 0.05;
    path.lineTo(x - mw, base - h * 0.30);
    path.lineTo(x - mw, base - h * 0.60);
    // little dome cap
    path.quadraticBezierTo(x, base - h * 0.74, x + mw, base - h * 0.60);
    path.lineTo(x + mw, base - h * 0.30);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
