# MeiTuanDeskPet

跨平台 Flutter 桌面宠物 —— 基于 Flutter Desktop（macOS / Windows / Linux），参考 LuoXiaoHeiPet 项目。

当前宠物是根据提供的白猫照片重新生成的写实风格 sprite，作为透明桌面宠物运行。

## 功能

- **透明无边框窗口** —— 始终置顶、无标题栏
- **写实白猫素材** —— 使用 `assets/animations/white-cat-bow.webp` 渲染
- **点击摸摸** —— 单击播放一次短动画，然后回到静止 idle
- **按方向拖拽** —— 拖动窗口时根据鼠标移动方向切换 left/right 行走动画
- **更安静的 idle** —— idle 默认保持静止，不持续眨眼或循环晃动
- **跨平台** —— macOS / Windows / Linux

## 项目结构

```
assets/
└── animations/
    └── white-cat-bow.webp   # 8 x 9 透明 sprite atlas，单格 192 x 208
lib/
├── main.dart                 # 入口，初始化桌面窗口
├── app.dart                  # 透明 MaterialApp 根组件
├── window/
│   └── window_setup.dart     # window_manager 启动配置（尺寸/无边框/置顶）
└── pet/
    ├── pet_state.dart        # 心情枚举 + 不可变 PetState
    ├── pet_controller.dart   # ValueNotifier<PetState>，管理点击/拖拽状态
    ├── pet_view.dart         # Sprite atlas 渲染器
    └── pet_widget.dart       # GestureDetector 串联 tap + pan -> 控制器 / 原生窗口拖拽
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

## 宠物素材

- 通过 `hatch-pet` 工作流基于提供的白猫照片生成。
- Atlas 尺寸：`1536 x 1872`，8 列 x 9 行。
- 单帧尺寸：`192 x 208`。
- 当前应用已接入 idle、petted、dragging-left、dragging-right 状态。

## 待办

- [ ] 右键菜单（退出、设置、隐藏）
- [ ] 系统托盘
- [ ] 接入 waiting、running、review、failed、success 等更多生成动画行
- [ ] 通过 `shared_preferences` 持久化状态和位置

## 协议

MIT
