import 'package:flutter/material.dart';

import 'pet_state.dart';

class PetView extends StatelessWidget {
  const PetView({super.key, required this.mood});

  final PetMood mood;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1).animate(animation),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: _PetSprite(
        key: ValueKey(mood),
        mood: mood,
      ),
    );
  }
}

class _PetSprite extends StatelessWidget {
  const _PetSprite({super.key, required this.mood});

  final PetMood mood;

  @override
  Widget build(BuildContext context) {
    final palette = _palette(mood);
    final label = mood == PetMood.petted ? '摸摸 ♥' : '美团';

    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [palette.highlight, palette.base],
          radius: 0.85,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.base.withValues(alpha: 0.45),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: mood == PetMood.petted ? 26 : 30,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  _Palette _palette(PetMood mood) {
    switch (mood) {
      case PetMood.idle:
        return const _Palette(
          base: Color(0xFFFFC107),
          highlight: Color(0xFFFFE082),
        );
      case PetMood.petted:
        return const _Palette(
          base: Color(0xFFFF7043),
          highlight: Color(0xFFFFAB91),
        );
    }
  }
}

class _Palette {
  const _Palette({required this.base, required this.highlight});

  final Color base;
  final Color highlight;
}
