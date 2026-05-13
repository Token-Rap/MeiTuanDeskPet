# MeiTuanDeskPet

跨平台 Flutter 桌面宠物 —— 基于 Flutter Desktop（macOS / Windows / Linux），参考 LuoXiaoHeiPet 项目。

> 当前仅为框架骨架，已实现点击切换动画（摸摸）和窗口拖拽。

## 功能

- **透明无边框窗口** —— 始终置顶、无标题栏
- **点击摸摸** —— 单击在 `idle`（闲置）和 `petted`（被摸）两种状态之间切换
- **拖拽移动** —— 在宠物任意位置按住拖动可移动窗口
- **跨平台** —— macOS / Windows / Linux

## 项目结构

```
lib/
├── main.dart                 # 入口，初始化桌面窗口
├── app.dart                  # MaterialApp 根组件，使用透明 Scaffold
├── window/
│   └── window_setup.dart     # window_manager 启动配置（尺寸/无边框/置顶）
└── pet/
    ├── pet_state.dart        # 心情枚举 + 不可变 PetState
    ├── pet_controller.dart   # ValueNotifier<PetState>，带自动恢复定时器
    ├── pet_view.dart         # AnimatedSwitcher 在不同心情视觉之间切换（占位实现）
    └── pet_widget.dart       # GestureDetector 串联 tap + pan -> 控制器 / 窗口拖拽
```

## 运行

```bash
flutter pub get

# 选择你的平台
flutter run -d macos
flutter run -d windows
flutter run -d linux
```

## 技术栈

- Flutter 3.x（Dart 3.11+）
- [`window_manager`](https://pub.dev/packages/window_manager) —— 桌面窗口控制

## 待办

- [ ] 用 Sprite Sheet / Rive / Lottie 替换占位视觉
- [ ] 右键菜单（退出、设置、隐藏）
- [ ] 系统托盘
- [ ] 更多心情（睡觉、饿、无聊）
- [ ] 通过 `shared_preferences` 持久化状态和位置

## 协议

MIT
