import 'package:flutter/material.dart';
import '../theme.dart';

/// MindPay's mark: a countdown ring (echoing the pause popup) wrapped
/// around a pause glyph — the logo itself hints at what the app does,
/// rather than being a generic abstract shape.
class MindPayLogo extends StatelessWidget {
  final double size;
  const MindPayLogo({super.key, this.size = 88});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoPainter(),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer ring — a partial arc (~80%) rather than a full circle,
    // visually referencing the countdown ring in the pause dialog.
    final ringPaint = Paint()
      ..color = MindColors.pauseAmber
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - ringPaint.strokeWidth / 2),
      -1.35, // start angle (radians) — leaves a visible gap, like a clock face
      5.2,   // sweep angle — the "almost full" countdown look
      false,
      ringPaint,
    );

    // Soft filled backing circle so the pause bars read clearly
    // against any background.
    final backingPaint = Paint()..color = MindColors.forestLight;
    canvas.drawCircle(center, radius - ringPaint.strokeWidth * 1.6, backingPaint);

    // Center pause glyph — two rounded bars, drawn on top of the backing circle.
    final barPaint = Paint()..color = Colors.white;
    final barWidth = size.width * 0.11;
    final barHeight = size.width * 0.34;
    final gap = size.width * 0.10;

    final barTop = center.dy - barHeight / 2;
    final leftBarLeft = center.dx - gap / 2 - barWidth;
    final rightBarLeft = center.dx + gap / 2;
    final rrectRadius = Radius.circular(barWidth * 0.35);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(leftBarLeft, barTop, barWidth, barHeight),
        rrectRadius,
      ),
      barPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rightBarLeft, barTop, barWidth, barHeight),
        rrectRadius,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
