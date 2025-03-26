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
    // Increased duration to 2 seconds
    Duration duration = const Duration(milliseconds: 1000),
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
      // Increased duration to 2 seconds
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Use a custom curve to slow down the end of the animation
    _animation = CurvedAnimation(
      parent: _controller,
      // This curve slows down at the end
      curve: Curves.easeOutQuad,
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

    // Adjust the stem growth to be faster in the beginning
    // This leaves more time for the flower at the end
    final stemProgress = math.min(1.0, progress * 1.3);
    final stemHeight = size.height * 0.7 * stemProgress;

    // Draw the stem
    final stemPath = Path();
    stemPath.moveTo(centerX, bottomY);

    // Create a slightly curved stem
    final controlPoint1 = Offset(centerX - 10 * stemProgress, bottomY - stemHeight * 0.5);
    final controlPoint2 = Offset(centerX + 5 * stemProgress, bottomY - stemHeight * 0.8);
    final endPoint = Offset(centerX, bottomY - stemHeight);

    stemPath.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        endPoint.dx, endPoint.dy
    );

    canvas.drawPath(stemPath, stemPaint);

    // Only draw leaves and flower if progress is far enough
    if (progress > 0.2) { // Start leaves earlier (was 0.3)
      // Draw leaves
      final leafProgress = math.min(1.0, (progress - 0.2) / 0.3); // Faster leaf growth

      // Left leaf
      if (progress > 0.2) {
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
      if (progress > 0.4) { // Start right leaf earlier (was 0.5)
        final leafPath2 = Path();
        final leafStart = Offset(centerX, bottomY - stemHeight * 0.7);
        leafPath2.moveTo(leafStart.dx, leafStart.dy);

        final leafSize = size.width * 0.25 * math.min(1.0, (progress - 0.4) / 0.3);
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


    if (progress > 0.6) {
      final flowerProgress = math.min(1.0, (progress - 0.6) / 0.4);
      final flowerCenter = Offset(centerX, bottomY - stemHeight);

      // Draw flower petals - MUCH LARGER and SIMPLER
      final petalCount = 5;
      final petalSize = size.width * 0.3 * flowerProgress; // Larger petals

      for (int i = 0; i < petalCount; i++) {
        final angle = i * (2 * math.pi / petalCount);

        // Use very bright, highly visible colors
        final petalPaint = Paint()
          ..color = Colors.purple.shade300 // More visible color
          ..style = PaintingStyle.fill;

        // Draw simple ellipse petals
        canvas.save();
        canvas.translate(flowerCenter.dx, flowerCenter.dy);
        canvas.rotate(angle);

        // Draw a simple oval for each petal
        final petalRect = Rect.fromCenter(
          center: Offset(petalSize * 0.7, 0),
          width: petalSize * 1.4,
          height: petalSize * 0.7,
        );
        canvas.drawOval(petalRect, petalPaint);
        canvas.restore();
      }

      // Draw flower center - larger and brighter
      final centerPaint = Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.fill;
      canvas.drawCircle(flowerCenter, petalSize * 0.4, centerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PlantPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}