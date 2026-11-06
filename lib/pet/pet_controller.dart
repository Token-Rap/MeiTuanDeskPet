import 'dart:async';

import 'package:flutter/foundation.dart';

import 'pet_state.dart';

class PetController extends ValueNotifier<PetState> {
  PetController() : super(PetState.initial);

  static const Duration _petDuration = Duration(milliseconds: 1200);
  static const double _dragDirectionThreshold = 3;

  Timer? _revertTimer;
  double _directionDistance = 0;
  bool _dragging = false;
  PetMood _facing = PetMood.draggingRight;

  void pet() {
    _revertTimer?.cancel();
    value = value.copyWith(mood: PetMood.petted);
    _revertTimer = Timer(_petDuration, () {
      value = value.copyWith(mood: PetMood.idle);
    });
  }

  void startDrag({double deltaX = 0}) {
    _revertTimer?.cancel();
    _directionDistance = 0;
    _dragging = true;
    if (deltaX != 0) {
      _facing = deltaX < 0 ? PetMood.draggingLeft : PetMood.draggingRight;
    }
    value = value.copyWith(mood: _facing);
  }

  /// Incremental screen-space movement, rather than distance from drag start.
  void updateDrag(double deltaX) {
    if (!_dragging || deltaX == 0) return;
    if (_directionDistance.sign != deltaX.sign) _directionDistance = 0;
    _directionDistance += deltaX;
    if (_directionDistance.abs() < _dragDirectionThreshold) return;
    final facing = deltaX < 0 ? PetMood.draggingLeft : PetMood.draggingRight;
    _facing = facing;
    if (value.mood != facing) value = value.copyWith(mood: facing);
  }

  void endDrag() {
    _revertTimer?.cancel();
    _dragging = false;
    _directionDistance = 0;
    value = value.copyWith(mood: PetMood.idle);
  }

  @override
  void dispose() {
    _revertTimer?.cancel();
    super.dispose();
  }
}
