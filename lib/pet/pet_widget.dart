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

  Offset? _dragStartGlobal;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  Future<void> _onPanStart(DragStartDetails details) async {
    _controller.startDrag();
    _dragStartGlobal = details.globalPosition;
    if (_isDesktop) {
      await windowManager.startDragging();
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final dragStartGlobal = _dragStartGlobal;
    if (dragStartGlobal != null) {
      _controller.updateDrag(details.globalPosition.dx - dragStartGlobal.dx);
    }
  }

  void _onPanEnd(DragEndDetails _) {
    _dragStartGlobal = null;
    _controller.endDrag();
  }

  void _onPanCancel() {
    _dragStartGlobal = null;
    _controller.endDrag();
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
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onPanCancel: _onPanCancel,
          child: PetView(mood: state.mood),
        );
      },
    );
  }
}
