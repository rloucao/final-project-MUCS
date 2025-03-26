import 'package:flutter/material.dart';
import 'dart:math' as math;

class PageTransitionAnimation extends StatefulWidget {
  final Color color;
  final double size;
  final VoidCallback? onComplete;

  const PageTransitionAnimation({
    Key? key,
    this.color = Colors.green,
    this.size = 100.0,
    this.onComplete,
  }) : super(key: key);

  /// Static method to show the animation as an overlay
  static Future<void> show({
    required BuildContext context,
    Color color = Colors.green,
    double size = 100.0,
    Duration duration = const Duration(milliseconds: 1500),
  }) async {
    final overlayState = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black54,
        child: Center(
          child: PageTransitionAnimation(
            color: color,
            size: size,
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    await Future.delayed(duration);
    overlayEntry.remove();
  }

  @override
  State<PageTransitionAnimation> createState() => _PageTransitionAnimationState();
}

class _PageTransitionAnimationState extends State<PageTransitionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward().then((_) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return _buildGrowingPlant();
      },
    );
  }

  Widget _buildGrowingPlant() {
    return Container(
      width: widget.size,
      height: widget.size * 1.5,
      child: CustomPaint(
        painter: PlantPainter(
          progress: _animation.value,
          color: widget.color,
        ),
      ),
    );
  }
}

/// Custom painter for the growing plant
class PlantPainter extends CustomPainter {
  final double progress;
  final Color color;

  PlantPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = Colors.green.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final leafPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final flowerPaint = Paint()
      ..color = Colors.pink
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final bottomY = size.height;

    // Calculate how much of the plant to draw based on progress
    final stemHeight = size.height * 0.7 * progress;

    // Draw the stem
    final stemPath = Path();
    stemPath.moveTo(centerX, bottomY);

    // Create a slightly curved stem
    final controlPoint1 = Offset(centerX - 10 * progress, bottomY - stemHeight * 0.5);
    final controlPoint2 = Offset(centerX + 5 * progress, bottomY - stemHeight * 0.8);
    final endPoint = Offset(centerX, bottomY - stemHeight);

    stemPath.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        endPoint.dx, endPoint.dy
    );

    canvas.drawPath(stemPath, stemPaint);

    // Only draw leaves and flower if progress is far enough
    if (progress > 0.3) {
      // Draw leaves
      final leafProgress = math.min(1.0, (progress - 0.3) / 0.4);

      // Left leaf
      if (progress > 0.3) {
        final leafPath1 = Path();
        final leafStart = Offset(centerX, bottomY - stemHeight * 0.5);
        leafPath1.moveTo(leafStart.dx, leafStart.dy);

        final leafSize = size.width * 0.25 * leafProgress;
        final leafControlPoint1 = Offset(leafStart.dx - leafSize * 0.8, leafStart.dy - leafSize * 0.3);
        final leafEndPoint1 = Offset(leafStart.dx - leafSize, leafStart.dy - leafSize * 0.5);
        final leafControlPoint2 = Offset(leafStart.dx - leafSize * 0.3, leafStart.dy - leafSize * 0.8);

        leafPath1.cubicTo(
            leafControlPoint1.dx, leafControlPoint1.dy,
            leafControlPoint2.dx, leafControlPoint2.dy,
            leafStart.dx, leafStart.dy
        );

        canvas.drawPath(leafPath1, leafPaint);
      }

      // Right leaf
      if (progress > 0.5) {
        final leafPath2 = Path();
        final leafStart = Offset(centerX, bottomY - stemHeight * 0.7);
        leafPath2.moveTo(leafStart.dx, leafStart.dy);

        final leafSize = size.width * 0.25 * math.min(1.0, (progress - 0.5) / 0.3);
        final leafControlPoint1 = Offset(leafStart.dx + leafSize * 0.8, leafStart.dy - leafSize * 0.2);
        final leafEndPoint1 = Offset(leafStart.dx + leafSize, leafStart.dy - leafSize * 0.4);
        final leafControlPoint2 = Offset(leafStart.dx + leafSize * 0.3, leafStart.dy - leafSize * 0.7);

        leafPath2.cubicTo(
            leafControlPoint1.dx, leafControlPoint1.dy,
            leafControlPoint2.dx, leafControlPoint2.dy,
            leafStart.dx, leafStart.dy
        );

        canvas.drawPath(leafPath2, leafPaint);
      }
    }

    // Draw flower at the top if progress is high enough
    if (progress > 0.7) {
      final flowerProgress = math.min(1.0, (progress - 0.7) / 0.3);
      final flowerCenter = Offset(centerX, bottomY - stemHeight);
      final flowerRadius = size.width * 0.15 * flowerProgress;

      // Draw petals
      for (int i = 0; i < 5; i++) {
        final angle = i * math.pi * 2 / 5;
        final petalPath = Path();
        petalPath.moveTo(flowerCenter.dx, flowerCenter.dy);

        final petalEndPoint = Offset(
            flowerCenter.dx + flowerRadius * 1.8 * math.cos(angle),
            flowerCenter.dy + flowerRadius * 1.8 * math.sin(angle)
        );

        final controlPoint1 = Offset(
            flowerCenter.dx + flowerRadius * 1.2 * math.cos(angle - 0.3),
            flowerCenter.dy + flowerRadius * 1.2 * math.sin(angle - 0.3)
        );

        final controlPoint2 = Offset(
            flowerCenter.dx + flowerRadius * 1.2 * math.cos(angle + 0.3),
            flowerCenter.dy + flowerRadius * 1.2 * math.sin(angle + 0.3)
        );

        petalPath.cubicTo(
            controlPoint1.dx, controlPoint1.dy,
            controlPoint2.dx, controlPoint2.dy,
            petalEndPoint.dx, petalEndPoint.dy
        );

        petalPath.cubicTo(
            controlPoint2.dx, controlPoint2.dy,
            controlPoint1.dx, controlPoint1.dy,
            flowerCenter.dx, flowerCenter.dy
        );

        canvas.drawPath(petalPath, flowerPaint);
      }

      // Draw flower center
      final centerPaint = Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.fill;
      canvas.drawCircle(flowerCenter, flowerRadius * 0.5, centerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PlantPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}