import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

const Size kPetWindowSize = Size(180, 180);

Future<void> initDesktopWindow() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!_isDesktop) return;

  await windowManager.ensureInitialized();

  final options = WindowOptions(
    size: kPetWindowSize,
    minimumSize: kPetWindowSize,
    backgroundColor: Color(0x00000000),
    skipTaskbar: Platform.isWindows,
    titleBarStyle: TitleBarStyle.hidden,
    alwaysOnTop: true,
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.setAsFrameless();
    await windowManager.setHasShadow(false);
    await windowManager.setBackgroundColor(const Color(0x00000000));
    await windowManager.setAlwaysOnTop(true);
    await windowManager.show();
    await windowManager.focus();
  });
}

bool get _isDesktop =>
    Platform.isMacOS || Platform.isWindows || Platform.isLinux;
