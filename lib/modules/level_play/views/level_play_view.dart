import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:p2tch/app/constants/color_constants.dart';
import 'package:p2tch/app/models/level.dart';
import 'package:p2tch/app/theme/app_theme.dart';
import 'package:p2tch/app/utils/locale_utils.dart';

import '../../../app/routes/app_routes.dart';
import '../controllers/level_play_controller.dart';

enum _Aura { normal, fixed, dragging, hover }

class LevelPlayView extends GetView<LevelPlayController> {
  const LevelPlayView({super.key});

  static const double _cellSize = 120.0;

  @override
  Widget build(BuildContext context) {
    // Created once per LevelPlayView.build() (which GetBuilder's own
    // rebuilds below don't trigger), so it stays stable across every
    // tap/drop-driven rebuild - that's what lets _buildTile reach the same
    // _RippleLayerState via rippleKey.currentState on every call.
    final rippleKey = GlobalKey<_RippleLayerState>();

    return GetBuilder<LevelPlayController>(
      builder: (controller) {
        // Use default palette (which is of 'departure' category) if loading fails somehow.
        final palette =
            CategoryColors.palettes[controller.level?.category.categoryId] ??
                CategoryColors.palettes['departure']!;

        final Widget body;
        if (controller.isLoading) {
          body = const Center(child: CircularProgressIndicator());
        } else if (controller.errorMessage != null) {
          body = Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(controller.errorMessage!),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: controller.retry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else {
          final level = controller.level!;
          if (level.completed && !controller.completionSequenceStarted) {
            controller.completionSequenceStarted = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _playCompletionSequence(controller, level, palette, rippleKey);
            });
          }

          body = Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _levelUpperComponent(context, level, palette),
                Expanded(child: Container()),
                SizedBox(
                  width: level.width * _cellSize,
                  height: level.height * _cellSize,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _RippleLayer(
                          key: rippleKey,
                          color: palette.ripple,
                        ),
                      ),
                      for (final tileId in level.cells.keys)
                        _buildTile(
                          context,
                          controller,
                          level,
                          tileId,
                          rippleKey,
                          palette,
                        ),
                    ],
                  ),
                ),
                Expanded(child: Container()),
              ],
            ),
          );
        }

        return Theme(
          data: themeFromPalette(palette),
          child: Scaffold(body: body),
        );
      },
    );
  }

  Widget _levelUpperComponent(
    BuildContext context,
    Level level,
    CategoryPalette palette,
  ) {
    final levelName = level.category;
    final levelId = level.id;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: InkWell(
            onTap: () {
              Get.back();
            },
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            child: Icon(
              Icons.chevron_left,
              color: palette.text,
              size: 30,
            ),
          )
        ),
        Text(
          "${levelName.nameFor(currentLocaleKey())} - $levelId",
        ),
      ]
    );
  }

  // Positioned.top grows downward, but Level's coordinate system has (0,0)
  // at the bottom-left, so y needs to be flipped for row 0 to render at the
  // bottom of the screen.
  //
  // AnimatedPositioned interpolates automatically whenever it's rebuilt with
  // a different left/top than last time (ValueKey(tileId) is what lets it
  // recognize "the same tile moved" across a swap). Whether a tile is
  // currently being dragged, or is a valid/invalid drop target, is tracked
  // entirely by Draggable/DragTarget's own local builder state - no
  // controller state needed for that, only for the actual swap.
  Widget _buildTile(
    BuildContext context,
    LevelPlayController controller,
    Level level,
    int tileId,
    GlobalKey<_RippleLayerState> rippleKey,
    CategoryPalette palette,
  ) {
    final cell = level.cells[tileId]!;
    final (x, y) = level.positions[tileId]!;
    final center = _tileCenter(level, tileId);

    return AnimatedPositioned(
      key: ValueKey(tileId),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: x * _cellSize,
      top: (level.height - 1 - y) * _cellSize,
      width: _cellSize,
      height: _cellSize,
      onEnd: () => controller.onTileMoveAnimationEnd(),
      child: DragTarget<int>(
        onWillAcceptWithDetails: (details) =>
            !cell.fixed && details.data != tileId,
        onAcceptWithDetails: (details) {
          controller.onTileDrop(details.data, tileId);
        },
        
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          final aura = isHovering
              ? _Aura.hover
              : (cell.fixed ? _Aura.fixed : _Aura.normal);

          final tapArea = GestureDetector(
            onTap: () {
              controller.onTileTap(tileId);
              rippleKey.currentState?.addRipple(center);
            },
            child: _tileVisual(context, cell, aura, palette),
          );

          if (cell.fixed) {
            return tapArea;
          }

          return Draggable<int>(
            data: tileId,
            maxSimultaneousDrags: controller.canDrag ? 1 : 0,
            onDragStarted: () => controller.onDragStarted(),
            onDraggableCanceled: (velocity, offset) =>
                controller.onDragCanceled(),
            feedback: SizedBox(
              width: _cellSize,
              height: _cellSize,
              child: _tileVisual(context, cell, _Aura.dragging, palette),
            ),
            childWhenDragging: Opacity(opacity: 0.3, child: tapArea),
            child: tapArea,
          );
        },
      ),
    );
  }

  Widget _tileVisual(
    BuildContext context,
    LevelCell cell,
    _Aura aura,
    CategoryPalette palette,
  ) {
    final Color auraColor = switch (aura) {
      _Aura.fixed => palette.auraFixed,
      _Aura.dragging => palette.auraDragging,
      _Aura.hover => palette.auraHover,
      _Aura.normal => palette.border,
    };
    final bool emphasized = aura == _Aura.dragging || aura == _Aura.hover;

    return Container(
      margin: const EdgeInsets.all(16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.surface,
        boxShadow: [
          BoxShadow(
            color: auraColor.withValues(alpha: 0.7),
            blurRadius: emphasized ? 24 : 10,
            spreadRadius: emphasized ? 6 : 1,
          ),
        ],
      ),
      child: Container(child: Text('${cell.relativeSemitone}')), // TODO: Put something that can identify tiles.
    );
  }

  Offset _tileCenter(Level level, int tileId) {
    final (x, y) = level.positions[tileId]!;
    return Offset(
      (x + 0.5) * _cellSize,
      (level.height - 1 - y + 0.5) * _cellSize,
    );
  }

  /// Plays every tile's sound + ripple in ascending pitch order, 0.25s apart
  /// (120bpm quarter notes) - the same effect a tap produces - then waits 1s
  /// before showing the completion dialog. isClosed is checked at each step
  /// since this runs across several seconds of Future.delayed gaps, during
  /// which the user could navigate away (e.g. the header's back button,
  /// which isn't gated by the tap-blocking in onTileTap).
  Future<void> _playCompletionSequence(
    LevelPlayController controller,
    Level level,
    CategoryPalette palette,
    GlobalKey<_RippleLayerState> rippleKey,
  ) async {
    final orderedIds = level.cells.keys.toList()
      ..sort((a, b) => level.cells[a]!.relativeSemitone
          .compareTo(level.cells[b]!.relativeSemitone));

    for (var i = 0; i < orderedIds.length; i++) {
      if (controller.isClosed) return;
      final tileId = orderedIds[i];
      controller.playTileSound(tileId);
      rippleKey.currentState?.addRipple(_tileCenter(level, tileId));
      if (i < orderedIds.length - 1) {
        await Future.delayed(const Duration(milliseconds: 250));
      }
    }

    await Future.delayed(const Duration(seconds: 1));
    if (controller.isClosed) return;
    _showCompletionPopup(level, palette);
  }

  void _showCompletionPopup(Level level, CategoryPalette palette) {
    final isLastLevel = level.id >= level.category.levels;

    Get.dialog<void>(
      Theme(
        data: themeFromPalette(palette),
        child: Dialog(
          child: PopScope<void>(
            // Blocks the system back gesture/button from dismissing this
            // dialog. The explicit Get.back() calls in the buttons below
            // don't go through this gate - PopScope only intercepts
            // system-initiated pop attempts.
            canPop: false,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Cleared!'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(closeOverlays: true),
                        child: const Text('Level List'),
                      ),
                      if (!isLastLevel)
                        TextButton(
                          onPressed: () {
                            Get.back();
                            Get.offNamed(
                              Routes.levelPlay,
                              arguments: <String, dynamic>{
                                'category': level.category.categoryId,
                                'id': level.id + 1,
                              },
                              preventDuplicates: false,
                            );
                          },
                          child: const Text('Next Level'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}

/// A transparent overlay that draws expanding, fading rings from tapped/
/// dropped points. Purely cosmetic per-widget animation state, so it lives
/// here as a StatefulWidget rather than on LevelPlayController - it doesn't
/// need to survive a controller rebuild or be inspected by game logic,
/// just needs a TickerProvider, which a GetxController doesn't have.
class _RippleLayer extends StatefulWidget {
  const _RippleLayer({super.key, required this.color});

  final Color color;

  @override
  State<_RippleLayer> createState() => _RippleLayerState();
}

class _RippleLayerState extends State<_RippleLayer>
    with TickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 1800);
  static const _maxRadius = 1000.0;

  final List<_Ripple> _ripples = [];

  void addRipple(Offset center) {
    final animationController = AnimationController(
      vsync: this,
      duration: _duration,
    );
    final ripple = _Ripple(center: center, controller: animationController);

    setState(() => _ripples.add(ripple));

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _ripples.remove(ripple));
        animationController.dispose();
      }
    });
    animationController.forward();
  }

  @override
  void dispose() {
    for (final ripple in _ripples) {
      ripple.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          for (final ripple in _ripples) ripple.controller,
        ]),
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _RipplePainter(
              ripples: _ripples,
              color: widget.color,
              maxRadius: _maxRadius,
            ),
          );
        },
      ),
    );
  }
}

class _Ripple {
  _Ripple({required this.center, required this.controller});

  final Offset center;
  final AnimationController controller;
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({
    required this.ripples,
    required this.color,
    required this.maxRadius,
  });

  final List<_Ripple> ripples;
  final Color color;
  final double maxRadius;

  @override
  void paint(Canvas canvas, Size size) {
    for (final ripple in ripples) {
      final progress = ripple.controller.value;
      final paint = Paint()
        ..color = color.withValues(alpha: (1 - progress) * 1)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(ripple.center, maxRadius * progress, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) => true;
}