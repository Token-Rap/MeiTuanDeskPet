import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pet_state.dart';
import 'sprite_layout.dart';

enum PetCat {
  xiaotuan('小团', 'assets/animations/xiaotuan-v2.png', 'assets/animations/xiaotuan-sleep-v4.png', 166),
  xiaomei('小美', 'assets/animations/xiaomei-v2.png', 'assets/animations/xiaomei-sleep-v3.png', 148);

  const PetCat(this.label, this.asset, this.sleepAsset, this.displaySize);
  final String label;
  final String asset;
  final String sleepAsset;
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
  late Future<_CatImages> _spritesheet;
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
    _spritesheet = _loadCatImages();
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
      _spritesheet = _loadCatImages();
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
    return FutureBuilder<_CatImages>(
      future: _spritesheet,
      builder: (context, snapshot) {
        final images = snapshot.data;
        if (images == null) {
          return SizedBox.square(dimension: widget.cat.displaySize);
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
                spritesheet: widget.mood == PetMood.idle
                    ? images.sleep
                    : widget.mood == PetMood.petted && images.petted != null
                        ? images.petted! : images.main,
                petting: widget.mood == PetMood.petted && images.petted != null,
                sleeping: widget.mood == PetMood.idle,
                breath: _isPlayingIdleSleepMotion
                    ? math.sin(_controller.value * math.pi) * 0.015
                    : 0,
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

  Future<_CatImages> _loadCatImages() async {
    final main = await _loadImage(widget.cat.asset);
    final sleep = await _loadImage(widget.cat.sleepAsset);
    final petted = widget.cat == PetCat.xiaotuan
        ? await _loadImage('assets/animations/xiaotuan-petted-v4.png')
        : null;
    return _CatImages(main, sleep, petted);
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
    required this.sleeping,
    required this.petting,
    required this.breath,
    required this.row,
    required this.frame,
    required this.flip,
    required this.cat,
  });

  final ui.Image spritesheet;
  final bool sleeping;
  final bool petting;
  final double breath;
  final int row;
  final int frame;
  final bool flip;
  final PetCat cat;

  @override
  void paint(Canvas canvas, Size size) {
    if (cat == PetCat.xiaotuan && (sleeping || petting)) {
      // Bounds measured from the alpha silhouettes, padded to preserve whiskers.
      // Use one body width and one ground line instead of stretching cell grids.
      const bounds = [
        Rect.fromLTRB(26, 129, 587, 544),
        Rect.fromLTRB(647, 126, 1209, 544),
        Rect.fromLTRB(24, 706, 588, 1150),
        Rect.fromLTRB(648, 720, 1211, 1148),
      ];
      final source = sleeping ? const Rect.fromLTRB(24, 66, 1737, 861) : bounds[frame];
      final scale = size.width * 0.94 / (sleeping ? 1713 : 564);
      final height = source.height * scale * (1 + (sleeping ? breath : 0));
      final destination = Rect.fromLTWH(
        (size.width - source.width * scale) / 2,
        size.height * 0.94 - height,
        source.width * scale,
        height,
      );
      canvas.drawImageRect(spritesheet, source, destination,
          Paint()..filterQuality = FilterQuality.medium);
      return;
    }
    if (sleeping) {
      final source = Rect.fromLTWH(0, 0,
          spritesheet.width.toDouble(), spritesheet.height.toDouble());
      final width = size.width * 0.98;
      final height = width * source.height / source.width * (1 + breath);
      final destination = Rect.fromLTWH(
        (size.width - width) / 2, size.height * 0.94 - height, width, height,
      );
      canvas.drawImageRect(spritesheet, source, destination,
          Paint()..filterQuality = FilterQuality.medium);
      return;
    }
    // Keep a single source-pixel scale across poses. The atlas rows have
    // different heights; stretching every row into a square distorts the cat.
    final rowEdges = cat == PetCat.xiaotuan
        ? const [0.0, 0.265, 0.52, 0.76, 1.0]
        : const [0.0, 0.25, 0.51, 0.76, 1.0];
    final groundLines = cat == PetCat.xiaotuan
        ? const [320.0, 634.0, 892.0, 1181.0]
        : const [310.0, 628.0, 884.0, 1185.0];
    final source = Rect.fromLTWH(
      (frame % _kAtlasColumns) * (spritesheet.width / 4),
      rowEdges[row] * spritesheet.height,
      spritesheet.width / 4,
      (rowEdges[row + 1] - rowEdges[row]) * spritesheet.height,
    );
    final ground = groundLines[row] / 1254 * spritesheet.height;
    final destination = spriteDestination(
      source, ground, size, spritesheet.width / 4,
    );
    canvas.save();
    if (flip) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    canvas.drawImageRect(
      spritesheet,
      source,
      destination,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PetSpritePainter oldDelegate) {
    return oldDelegate.spritesheet != spritesheet ||
        oldDelegate.sleeping != sleeping ||
        oldDelegate.petting != petting ||
        oldDelegate.breath != breath ||
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

class _CatImages {
  const _CatImages(this.main, this.sleep, this.petted);
  final ui.Image main;
  final ui.Image sleep;
  final ui.Image? petted;
}
