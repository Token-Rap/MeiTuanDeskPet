# MeiTuanDeskPet

A cross-platform Flutter desktop pet — built with Flutter Desktop (macOS / Windows / Linux), inspired by the LuoXiaoHeiPet project.

> Framework-only scaffold. Currently provides tap-to-pet animation switching and window dragging.

中文版：[README_CN.md](./README_CN.md)

## Features

- **Transparent borderless window** — always on top, no title bar
- **Tap to pet (摸摸)** — single click switches between `idle` and `petted` moods
- **Drag to move** — pan anywhere on the pet to drag the window
- **Cross-platform** — macOS, Windows, Linux

## Project Structure

```
lib/
├── main.dart                 # Entry point — initialises desktop window
├── app.dart                  # MaterialApp root with transparent Scaffold
├── window/
│   └── window_setup.dart     # window_manager bootstrap (size / frameless / always-on-top)
└── pet/
    ├── pet_state.dart        # Mood enum + immutable PetState
    ├── pet_controller.dart   # ValueNotifier<PetState> with auto-revert timer
    ├── pet_view.dart         # AnimatedSwitcher between mood visuals (placeholder)
    └── pet_widget.dart       # GestureDetector wiring tap + pan → controller / window drag
```

## Run

```bash
flutter pub get

# Pick the platform you're on
flutter run -d macos
flutter run -d windows
flutter run -d linux
```

## Tech Stack

- Flutter 3.x (Dart 3.11+)
- [`window_manager`](https://pub.dev/packages/window_manager) — desktop window control

## Roadmap

- [ ] Replace placeholder visuals with sprite-sheet / Rive / Lottie animations
- [ ] Right-click context menu (exit, settings, hide)
- [ ] System tray integration
- [ ] More moods (sleep, hungry, idle-bored)
- [ ] Persistence (mood, position) via `shared_preferences`

## License

MIT
