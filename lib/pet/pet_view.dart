import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pet_state.dart';

const String _kWhiteCatSpritesheet =
    'assets/animations/white-cat-bow.webp';
const String _kWhiteCatSleepSpritesheet =
    'assets/animations/white-cat-sleep.png';
const int _kCellWidth = 192;
const int _kCellHeight = 208;
const int _kAtlasColumns = 8;
const Duration _kIdleSleepPause = Duration(minutes: 25);

class PetView extends StatefulWidget {
  const PetView({super.key, required this.mood});

  final PetMood mood;

  @override
  State<PetView> createState() => _PetViewState();
}

class _PetViewState extends State<PetView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Future<_SpriteImages> _spritesheets;
  Timer? _idleSleepTimer;
  bool _isPlayingIdleSleepMotion = false;

  _AnimationSpec get _spec => switch (widget.mood) {
        PetMood.idle => _isPlayingIdleSleepMotion
            ? const _AnimationSpec(
                sheet: _SpriteSheet.sleep,
                row: 0,
                frames: 6,
                frameDuration: Duration(milliseconds: 520),
                loops: false,
              )
            : const _AnimationSpec(
                sheet: _SpriteSheet.sleep,
                row: 0,
                frames: 1,
              ),
        PetMood.petted => const _AnimationSpec(
            row: 3,
            frames: 4,
            frameDuration: Duration(milliseconds: 260),
            loops: false,
          ),
        PetMood.draggingRight => const _AnimationSpec(row: 1, frames: 8),
        PetMood.draggingLeft => const _AnimationSpec(row: 2, frames: 8),
      };

  @override
  void initState() {
    super.initState();
    _spritesheets = _loadSpritesheets();
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
    return FutureBuilder<_SpriteImages>(
      future: _spritesheets,
      builder: (context, snapshot) {
        final images = snapshot.data;
        if (images == null) {
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
            final nextRawFrame = currentRawFrame + 1;
            final nextFrame = spec.loops
                ? nextRawFrame % spec.frames
                : nextRawFrame.clamp(0, spec.frames - 1);
            final blend = spec.isAnimated
                ? Curves.easeInOut.transform(framePosition.frac())
                : 0.0;

            return CustomPaint(
              size: const Size(208, 208),
              painter: _PetSpritePainter(
                spritesheet: images.forSheet(spec.sheet),
                row: spec.row,
                frame: currentFrame,
                nextFrame: nextFrame,
                blend: currentFrame == nextFrame ? 0 : blend,
              ),
            );
          },
        );
      },
    );
  }

  Future<_SpriteImages> _loadSpritesheets() async {
    final main = await _loadImage(_kWhiteCatSpritesheet);
    final sleep = await _loadImage(_kWhiteCatSleepSpritesheet);
    return _SpriteImages(main: main, sleep: sleep);
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
    required this.nextFrame,
    required this.blend,
  });

  final ui.Image spritesheet;
  final int row;
  final int frame;
  final int nextFrame;
  final double blend;

  @override
  void paint(Canvas canvas, Size size) {
    final fitted = applyBoxFit(
      BoxFit.contain,
      const Size(_kCellWidth * 1.0, _kCellHeight * 1.0),
      size,
    );
    final destination = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & size,
    );

    _drawFrame(canvas, destination, frame, 1 - blend);
    if (blend > 0) {
      _drawFrame(canvas, destination, nextFrame, blend);
    }
  }

  void _drawFrame(
    Canvas canvas,
    Rect destination,
    int frame,
    double opacity,
  ) {
    final source = Rect.fromLTWH(
      (frame % _kAtlasColumns) * _kCellWidth.toDouble(),
      row * _kCellHeight.toDouble(),
      _kCellWidth.toDouble(),
      _kCellHeight.toDouble(),
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
        oldDelegate.nextFrame != nextFrame ||
        oldDelegate.blend != blend;
  }
}

class _AnimationSpec {
  const _AnimationSpec({
    required this.row,
    required this.frames,
    this.sheet = _SpriteSheet.main,
    this.frameDuration = const Duration(milliseconds: 140),
    this.loops = true,
  });

  final int row;
  final _SpriteSheet sheet;
  final int frames;
  final Duration frameDuration;
  final bool loops;

  bool get isAnimated => frames > 1;

  Duration get duration => frameDuration * frames;
}

enum _SpriteSheet { main, sleep }

class _SpriteImages {
  const _SpriteImages({required this.main, required this.sleep});

  final ui.Image main;
  final ui.Image sleep;

  ui.Image forSheet(_SpriteSheet sheet) => switch (sheet) {
        _SpriteSheet.main => main,
        _SpriteSheet.sleep => sleep,
      };
}

extension on double {
  double frac() => this - floorToDouble();
}
