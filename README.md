# MeiTuanDeskPet

A cross-platform Flutter desktop pet — built with Flutter Desktop (macOS / Windows / Linux), inspired by the LuoXiaoHeiPet project.

The current pet is a generated photorealistic white cat sprite, rebuilt from the provided reference photos and packaged as a transparent desktop companion.

中文版：[README_CN.md](./README_CN.md)

## Features

- **Transparent borderless window** — always on top, no title bar
- **Photorealistic white cat sprite** — rendered from `assets/animations/white-cat-bow.webp`
- **Tap to pet (摸摸)** — single click plays one short greeting animation, then returns to idle
- **Direction-aware dragging** — drag the pet window and the cat switches between left/right walking rows based on pointer movement
- **Still idle pose** — idle is intentionally quiet instead of constantly blinking or looping
- **Cross-platform** — macOS, Windows, Linux

## Project Structure

```
assets/
└── animations/
    └── white-cat-bow.webp   # 8 x 9 transparent sprite atlas, 192 x 208 cells
lib/
├── main.dart                 # Entry point — initialises desktop window
├── app.dart                  # Transparent MaterialApp root
├── window/
│   └── window_setup.dart     # window_manager bootstrap (size / frameless / always-on-top)
└── pet/
    ├── pet_state.dart        # Mood enum + immutable PetState
    ├── pet_controller.dart   # ValueNotifier<PetState> with tap/drag mood control
    ├── pet_view.dart         # Sprite atlas renderer
    └── pet_widget.dart       # GestureDetector wiring tap + pan -> controller / native window drag
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

## Pet Asset

- Generated with the `hatch-pet` workflow from the supplied white cat references.
- Atlas size: `1536 x 1872`, 8 columns x 9 rows.
- Cell size: `192 x 208`.
- Active app states currently use idle, petted, dragging-left, and dragging-right rows.

## Roadmap

- [ ] Right-click context menu (exit, settings, hide)
- [ ] System tray integration
- [ ] Wire additional generated rows for waiting, running, review, failed, and success states
- [ ] Persistence (mood, position) via `shared_preferences`

## License

MIT
