import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pet_state.dart';

enum PetCat {
  xiaotuan('小团', 'assets/animations/xiaotuan-v2.png', 208),
  xiaomei('小美', 'assets/animations/xiaomei-v2.png', 184);

  const PetCat(this.label, this.asset, this.displaySize);
  final String label;
  final String asset;
  final double displaySize;
}

const int _kAtlasColumns = 4;
const Duration _kIdleSleepPause = Duration(minutes: 25);

class PetView extends StatefulWidget {
  const PetView({super.key, required this.mood, this.cat = PetCat.xiaotuan});

  final PetMood mood;
  final PetCat cat;

  @override
  State<PetView> createState() => _PetViewState();
}

class _PetViewState extends State<PetView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Future<ui.Image> _spritesheet;
  Timer? _idleSleepTimer;
  bool _isPlayingIdleSleepMotion = false;

  _AnimationSpec get _spec => switch (widget.mood) {
        PetMood.idle => _isPlayingIdleSleepMotion
            ? const _AnimationSpec(
                row: 3,
                frames: 4,
                frameDuration: Duration(milliseconds: 520),
                loops: false,
              )
            : const _AnimationSpec(
                row: 3,
                frames: 1,
              ),
        PetMood.petted => const _AnimationSpec(
            row: 1,
            frames: 4,
            frameDuration: Duration(milliseconds: 260),
            loops: false,
          ),
        PetMood.draggingRight => const _AnimationSpec(row: 2, frames: 4),
        PetMood.draggingLeft => const _AnimationSpec(row: 2, frames: 4),
      };

  @override
  void initState() {
    super.initState();
    _spritesheet = _loadImage(widget.cat.asset);
    _controller = AnimationController(
      vsync: this,
      duration: _spec.duration,
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(PetView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cat != widget.cat) {
      _spritesheet = _loadImage(widget.cat.asset);
    }
    if (oldWidget.mood == widget.mood && oldWidget.cat == widget.cat) return;
    _syncAnimation();
  }

  void _syncAnimation() {
    _idleSleepTimer?.cancel();
    if (widget.mood == PetMood.idle) {
      _isPlayingIdleSleepMotion = false;
      _play(_spec);
      _scheduleIdleSleepMotion();
      return;
    }

    _play(_spec);
  }

  void _scheduleIdleSleepMotion() {
    _idleSleepTimer = Timer(_kIdleSleepPause, () {
      if (!mounted || widget.mood != PetMood.idle) return;
      setState(() {
        _isPlayingIdleSleepMotion = true;
      });
      _play(_spec);

      _idleSleepTimer = Timer(_spec.duration, () {
        if (!mounted || widget.mood != PetMood.idle) return;
        setState(() {
          _isPlayingIdleSleepMotion = false;
        });
        _play(_spec);
        _scheduleIdleSleepMotion();
      });
    });
  }

  void _play(_AnimationSpec spec) {
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
    _idleSleepTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.Image>(
      future: _spritesheet,
      builder: (context, snapshot) {
        final spritesheet = snapshot.data;
        if (spritesheet == null) {
          return const SizedBox.square(dimension: 208);
        }

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final spec = _spec;
            final framePosition = spec.isAnimated
                ? _controller.value * spec.frames
                : 0.0;
            final currentRawFrame = framePosition.floor();
            final currentFrame = spec.loops
                ? currentRawFrame % spec.frames
                : currentRawFrame.clamp(0, spec.frames - 1);
            return CustomPaint(
              size: Size.square(widget.cat.displaySize),
              painter: _PetSpritePainter(
                spritesheet: spritesheet,
                row: spec.row,
                frame: currentFrame,
                flip: widget.mood == PetMood.draggingLeft,
                cat: widget.cat,
              ),
            );
          },
        );
      },
    );
  }

  Future<ui.Image> _loadImage(String asset) async {
    final data = await rootBundle.load(asset);
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
    required this.flip,
    required this.cat,
  });

  final ui.Image spritesheet;
  final int row;
  final int frame;
  final bool flip;
  final PetCat cat;

  @override
  void paint(Canvas canvas, Size size) {
    final fitted = applyBoxFit(
      BoxFit.contain,
      Size(spritesheet.width / 4, spritesheet.height / 4),
      size,
    );
    final destination = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & size,
    );

    canvas.save();
    if (flip) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    _drawFrame(canvas, destination, frame, 1);
    canvas.restore();
  }

  void _drawFrame(
    Canvas canvas,
    Rect destination,
    int frame,
    double opacity,
  ) {
    // Generated rows have slightly different vertical spacing. Use their
    // measured boundaries so paws are not cut at an assumed quarter line.
    final rowEdges = cat == PetCat.xiaotuan
        ? const [0.0, 0.265, 0.52, 0.76, 1.0]
        : const [0.0, 0.25, 0.51, 0.76, 1.0];
    final source = Rect.fromLTWH(
      (frame % _kAtlasColumns) * (spritesheet.width / 4),
      rowEdges[row] * spritesheet.height,
      (spritesheet.width / 4),
      (rowEdges[row + 1] - rowEdges[row]) * spritesheet.height,
    );
    canvas.drawImageRect(
      spritesheet,
      source,
      destination,
      Paint()..color = Color.fromRGBO(255, 255, 255, opacity),
    );
  }

  @override
  bool shouldRepaint(_PetSpritePainter oldDelegate) {
    return oldDelegate.spritesheet != spritesheet ||
        oldDelegate.row != row ||
        oldDelegate.frame != frame ||
        oldDelegate.flip != flip ||
        oldDelegate.cat != cat;
  }
}

class _AnimationSpec {
  const _AnimationSpec({
    required this.row,
    required this.frames,
    this.frameDuration = const Duration(milliseconds: 140),
    this.loops = true,
  });

  final int row;
  final int frames;
  final Duration frameDuration;
  final bool loops;

  bool get isAnimated => frames > 1;

  Duration get duration => frameDuration * frames;
}
