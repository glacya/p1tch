import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:p2tch/app/constants/color_constants.dart';

import '../controllers/level_loading_controller.dart';

/// A blackout screen shown while LevelLoadingController loads a level's
/// data + audio in the background - _load() navigates onward on its own
/// once done (or on failure/timeout), so nothing here reads controller
/// state for display. It still needs to be a GetView (not a plain
/// StatelessWidget): referencing `controller` below is what actually
/// instantiates it via Get.find() - LevelLoadingBinding only registers a
/// lazy factory, so without this reference onInit()/_load() would never
/// run and the screen would sit on the spinner forever.
class LevelLoadingView extends GetView<LevelLoadingController> {
  const LevelLoadingView({super.key});

  static const _fadeOutDuration = Duration(milliseconds: 500);

  @override
  Widget build(BuildContext context) {
    final palette = CategoryColors.palettes[controller.category] ??
        CategoryColors.palettes['departure']!;

    return GetBuilder<LevelLoadingController>(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        body: AnimatedOpacity(
          opacity: controller.isFadingOut ? 0.0 : 1.0,
          duration: _fadeOutDuration,
          child: Stack(
            children: [
              Positioned.fill(child: _FloatingCircles(color: palette.ripple)),
              const Center(child: Text("불러오는 중..")),
            ],
          ),
        ),
      ),
    );
  }
}

/// Decorative background: circles of random size/position drifting in a
/// fixed direction, slower the bigger they are. Purely cosmetic, so it
/// lives as its own StatefulWidget rather than on LevelLoadingController -
/// same reasoning as level_play's _RippleLayer.
class _FloatingCircles extends StatefulWidget {
  const _FloatingCircles({required this.color});

  final Color color;

  @override
  State<_FloatingCircles> createState() => _FloatingCirclesState();
}

class _FloatingCirclesState extends State<_FloatingCircles>
    with SingleTickerProviderStateMixin {
  static const _circleCount = 50;
  static const _minRadius = 40.0;
  static const _maxRadius = 160.0;
  // speed = _speedConstant / radius, so the smallest circle moves fastest.
  static const _speedConstant = 10000.0;

  late final Ticker _ticker;
  late final List<_Circle> _circles;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _circles = List.generate(_circleCount, (_) {
      final radius =
          _minRadius + random.nextDouble() * (_maxRadius - _minRadius);
      return _Circle(
        originFraction: Offset(random.nextDouble(), random.nextDouble()),
        radius: radius,
        speed: _speedConstant / radius,
      );
    });
    _ticker = createTicker((elapsed) => setState(() => _elapsed = elapsed))
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _FloatingCirclesPainter(
          circles: _circles,
          elapsedSeconds:
              _elapsed.inMicroseconds / Duration.microsecondsPerSecond,
          color: widget.color,
        ),
      ),
    );
  }
}

class _Circle {
  _Circle({
    required this.originFraction,
    required this.radius,
    required this.speed,
  });

  /// Starting position as a 0..1 fraction of the canvas size.
  final Offset originFraction;
  final double radius;

  /// Speed in px/sec along the shared direction vector.
  final double speed;
}

class _FloatingCirclesPainter extends CustomPainter {
  _FloatingCirclesPainter({
    required this.circles,
    required this.elapsedSeconds,
    required this.color,
  });

  final List<_Circle> circles;
  final double elapsedSeconds;
  final Color color;

  // Shared movement direction for every circle, normalized once.
  static const _rawDirection = Offset(-2, 1);
  static final Offset _direction = _rawDirection / _rawDirection.distance;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.25);

    for (final circle in circles) {
      final origin = Offset(
        circle.originFraction.dx * size.width,
        circle.originFraction.dy * size.height,
      );
      final travel = _direction * circle.speed * elapsedSeconds;

      // Wrap in a space padded by the radius on each side, so a circle
      // fully exits the visible canvas before reappearing on the other
      // edge instead of popping into view mid-circle.
      final wrapWidth = size.width + circle.radius * 2;
      final wrapHeight = size.height + circle.radius * 2;
      final dx = (origin.dx + travel.dx + circle.radius) % wrapWidth;
      final dy = (origin.dy + travel.dy + circle.radius) % wrapHeight;

      canvas.drawCircle(
        Offset(dx - circle.radius, dy - circle.radius),
        circle.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingCirclesPainter oldDelegate) =>
      oldDelegate.elapsedSeconds != elapsedSeconds;
}
