import 'dart:async';

import 'package:flutter/foundation.dart';

import 'pet_state.dart';

class PetController extends ValueNotifier<PetState> {
  PetController() : super(PetState.initial);

  static const Duration _petDuration = Duration(milliseconds: 1500);

  Timer? _revertTimer;

  void pet() {
    _revertTimer?.cancel();
    value = value.copyWith(mood: PetMood.petted);
    _revertTimer = Timer(_petDuration, () {
      value = value.copyWith(mood: PetMood.idle);
    });
  }

  @override
  void dispose() {
    _revertTimer?.cancel();
    super.dispose();
  }
}
