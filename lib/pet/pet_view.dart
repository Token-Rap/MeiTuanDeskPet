import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pet_state.dart';

const String _kWhiteCatSpritesheet =
    'assets/animations/white-cat-bow.webp';
const int _kCellWidth = 192;
const int _kCellHeight = 208;
const int _kAtlasColumns = 8;

class PetView extends StatefulWidget {
  const PetView({super.key, required this.mood});

  final PetMood mood;

  @override
  State<PetView> createState() => _PetViewState();
}

class _PetViewState extends State<PetView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Future<ui.Image> _spritesheet;

  _AnimationSpec get _spec => switch (widget.mood) {
        PetMood.idle => const _AnimationSpec(row: 0, frames: 1),
        PetMood.petted => const _AnimationSpec(
            row: 3,
            frames: 4,
            loops: false,
          ),
        PetMood.draggingRight => const _AnimationSpec(row: 1, frames: 8),
        PetMood.draggingLeft => const _AnimationSpec(row: 2, frames: 8),
      };

  @override
  void initState() {
    super.initState();
    _spritesheet = _loadSpritesheet();
    _controller = AnimationController(
      vsync: this,
      duration: _spec.duration,
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(PetView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood == widget.mood) return;
    _syncAnimation();
  }

  void _syncAnimation() {
    final spec = _spec;
    _controller.duration = spec.duration;
    if (spec.isAnimated && spec.loops) {
      _controller
        ..forward(from: 0)
        ..repeat();
    } else if (spec.isAnimated) {
      _controller.forward(from: 0);
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.Image>(
      future: _spritesheet,
      builder: (context, snapshot) {
        final image = snapshot.data;
        if (image == null) {
          return const SizedBox.square(dimension: 208);
        }

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final spec = _spec;
            final rawFrame = spec.isAnimated
                ? (_controller.value * spec.frames).floor()
                : 0;
            final frame = spec.loops
                ? rawFrame % spec.frames
                : rawFrame.clamp(0, spec.frames - 1);

            return CustomPaint(
              size: const Size(208, 208),
              painter: _PetSpritePainter(
                spritesheet: image,
                row: spec.row,
                frame: frame,
              ),
            );
          },
        );
      },
    );
  }

  Future<ui.Image> _loadSpritesheet() async {
    final data = await rootBundle.load(_kWhiteCatSpritesheet);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}

class _PetSpritePainter extends CustomPainter {
  const _PetSpritePainter({
    required this.spritesheet,
    required this.row,
    required this.frame,
  });

  final ui.Image spritesheet;
  final int row;
  final int frame;

  @override
  void paint(Canvas canvas, Size size) {
    final source = Rect.fromLTWH(
      (frame % _kAtlasColumns) * _kCellWidth.toDouble(),
      row * _kCellHeight.toDouble(),
      _kCellWidth.toDouble(),
      _kCellHeight.toDouble(),
    );
    final fitted = applyBoxFit(
      BoxFit.contain,
      const Size(_kCellWidth * 1.0, _kCellHeight * 1.0),
      size,
    );
    final destination = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & size,
    );

    canvas.drawImageRect(spritesheet, source, destination, Paint());
  }

  @override
  bool shouldRepaint(_PetSpritePainter oldDelegate) {
    return oldDelegate.spritesheet != spritesheet ||
        oldDelegate.row != row ||
        oldDelegate.frame != frame;
  }
}

class _AnimationSpec {
  const _AnimationSpec({
    required this.row,
    required this.frames,
    this.loops = true,
  });

  final int row;
  final int frames;
  final bool loops;

  bool get isAnimated => frames > 1;

  Duration get duration => Duration(milliseconds: frames * 140);
}
