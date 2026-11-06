import 'package:flutter/widgets.dart';

import 'app.dart';
import 'desktop/desktop_shell.dart';
import 'window/window_setup.dart';

Future<void> main() async {
  await initDesktopWindow();
  runApp(const MeiTuanDeskPetApp());
  await DesktopShell.instance.initialize();
}
