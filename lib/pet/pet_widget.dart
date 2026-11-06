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

class _PetWidgetState extends State<PetWidget> with WindowListener {
  final PetController _controller = PetController();

  PetCat _cat = PetCat.xiaotuan;
  Offset? _dragStartGlobal;
  bool _nativeDragging = false;
  Offset? _lastWindowPosition;
  int _dragSession = 0;
  bool _readingPosition = false;
  bool _positionPending = false;

  @override
  void initState() {
    super.initState();
    if (_isDesktop) windowManager.addListener(this);
  }

  @override
  void onWindowMove() {
    if (!_nativeDragging) return;
    _positionPending = true;
    if (!_readingPosition) _readWindowPosition();
  }

  Future<void> _readWindowPosition() async {
    _readingPosition = true;
    final session = _dragSession;
    try {
      while (_positionPending && _nativeDragging && mounted) {
        _positionPending = false;
        final position = await windowManager.getPosition();
        if (!mounted || !_nativeDragging || session != _dragSession) return;
        final previous = _lastWindowPosition;
        _lastWindowPosition = position;
        if (previous != null) _controller.updateDrag(position.dx - previous.dx);
      }
    } finally {
      _readingPosition = false;
      if (_positionPending && _nativeDragging && mounted) _readWindowPosition();
    }
  }

  @override
  void dispose() {
    if (_isDesktop) windowManager.removeListener(this);
    _dragSession++;
    _controller.dispose();
    super.dispose();
  }

  bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  Future<void> _onPanStart(DragStartDetails details) async {
    final pressPosition = _dragStartGlobal ?? details.globalPosition;
    _controller.startDrag(deltaX: details.globalPosition.dx - pressPosition.dx);
    if (_isDesktop) {
      _nativeDragging = Platform.isWindows;
      final session = ++_dragSession;
      try {
        if (Platform.isWindows) {
          final position = await windowManager.getPosition();
          if (!mounted || session != _dragSession) return;
          _lastWindowPosition = position;
        }
        await windowManager.startDragging();
      } finally {
        _nativeDragging = false;
        _dragSession++;
        _positionPending = false;
        _lastWindowPosition = null;
        if (mounted && Platform.isWindows) {
          _dragStartGlobal = null;
          _controller.endDrag();
        }
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // Native Windows dragging uses screen-space window move events instead.
    if (!_nativeDragging) _controller.updateDrag(details.delta.dx);
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
