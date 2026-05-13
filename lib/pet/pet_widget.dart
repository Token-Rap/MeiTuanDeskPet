import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'pet_controller.dart';
import 'pet_state.dart';
import 'pet_view.dart';

class PetWidget extends StatefulWidget {
  const PetWidget({super.key});

  @override
  State<PetWidget> createState() => _PetWidgetState();
}

class _PetWidgetState extends State<PetWidget> {
  final PetController _controller = PetController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  void _onPanStart(DragStartDetails _) {
    if (_isDesktop) {
      windowManager.startDragging();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PetState>(
      valueListenable: _controller,
      builder: (context, state, _) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _controller.pet,
          onPanStart: _onPanStart,
          child: PetView(mood: state.mood),
        );
      },
    );
  }
}
