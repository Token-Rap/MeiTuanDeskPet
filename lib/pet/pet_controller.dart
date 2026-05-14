import 'dart:async';

import 'package:flutter/foundation.dart';

import 'pet_state.dart';

class PetController extends ValueNotifier<PetState> {
  PetController() : super(PetState.initial);

  static const Duration _petDuration = Duration(milliseconds: 620);
  static const double _dragDirectionThreshold = 18;

  Timer? _revertTimer;
  PetMood? _lockedDragMood;

  void pet() {
    _revertTimer?.cancel();
    value = value.copyWith(mood: PetMood.petted);
    _revertTimer = Timer(_petDuration, () {
      value = value.copyWith(mood: PetMood.idle);
    });
  }

  void startDrag() {
    _revertTimer?.cancel();
    _lockedDragMood = null;
    value = value.copyWith(mood: PetMood.draggingRight);
  }

  void updateDrag(double totalDeltaX) {
    if (_lockedDragMood == null &&
        totalDeltaX.abs() >= _dragDirectionThreshold) {
      _lockedDragMood =
          totalDeltaX < 0 ? PetMood.draggingLeft : PetMood.draggingRight;
      value = value.copyWith(mood: _lockedDragMood);
    }
  }

  void endDrag() {
    _revertTimer?.cancel();
    _lockedDragMood = null;
    value = value.copyWith(mood: PetMood.idle);
  }

  @override
  void dispose() {
    _revertTimer?.cancel();
    super.dispose();
  }
}
