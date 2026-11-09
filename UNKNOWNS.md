# Unknowns

## Pre
- User confirmed v0.2.0-preview.10 (f531ba7) is the expected latest version.
- Existing preview tray is retained. Hide only the Windows taskbar button, including startup.
- No remaining design-changing questions; preserve existing cat assets and features.

## During
- Earlier implementation targeted outdated main; preserved it in Git stash.
- Created fix/windows-tray-only from origin/preview/windows-cats; no new tray implementation needed.
- The native window can appear before Flutter applies its options; WS_EX_TOOLWINDOW prevents a taskbar flash during startup.
- Existing WM_CLOSE behavior hides to the tray rather than terminating. Verified that behavior and restored the pet through the existing tray callback, leaving the correct build running.

## Post
- Explainer: The expected code was already pushed on preview/windows-cats, while main remained at v0.1.0. The final change uses preview.10 and hides the Windows taskbar button both at native creation and in Flutter setup. Existing tray menus, cat assets, and update behavior are retained.
- Built and launched version 0.2.0+10 from v0.2.0-preview.10 with the taskbar-only changes.
- Flutter analysis, all 13 Flutter tests, the Python test, and C++ review passed.
- Runtime checks passed: visible pet, tool-window style with no app-window style, both cat window icons, close-to-tray, and restore through the existing tray callback.
- User confirmed the expected version; no additional design questions remain.
- Quiz 1: Why did the initial run use an old version? User correctly answered that the build used old main while the newer code was on preview/windows-cats. No gap found.
- Quiz 2: How should the tray-only pet be exited? User correctly answered to select Exit in the system tray menu. No gap found.
