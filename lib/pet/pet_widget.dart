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

  PetCat _cat = PetCat.xiaotuan;
  Offset? _dragStartGlobal;
  bool _nativeDragging = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  Future<void> _onPanStart(DragStartDetails details) async {
    final pressPosition = _dragStartGlobal ?? details.globalPosition;
    _controller.startDrag();
    _controller.updateDrag(details.globalPosition.dx - pressPosition.dx);
    if (_isDesktop) {
      _nativeDragging = Platform.isWindows;
      try {
        await windowManager.startDragging();
      } finally {
        _nativeDragging = false;
        if (mounted && Platform.isWindows) {
          _dragStartGlobal = null;
          _controller.endDrag();
        }
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final dragStartGlobal = _dragStartGlobal;
    if (dragStartGlobal != null) {
      _controller.updateDrag(details.globalPosition.dx - dragStartGlobal.dx);
    }
  }

  void _onPanEnd(DragEndDetails _) {
    if (_nativeDragging) return;
    _dragStartGlobal = null;
    _controller.endDrag();
  }

  void _onPanCancel() {
    if (_nativeDragging) return;
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
          onSecondaryTap: () {
            _controller.endDrag();
            setState(() {
              _cat = _cat == PetCat.xiaotuan ? PetCat.xiaomei : PetCat.xiaotuan;
            });
          },
          onPanDown: (details) => _dragStartGlobal = details.globalPosition,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onPanCancel: _onPanCancel,
          child: PetView(key: ValueKey(_cat), mood: state.mood, cat: _cat),
        );
      },
    );
  }
}
