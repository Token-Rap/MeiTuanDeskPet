# MeiTuanDeskPet

跨平台 Flutter 桌面宠物 —— 基于 Flutter Desktop（macOS / Windows / Linux），参考 LuoXiaoHeiPet 项目。

当前宠物以小团（白猫）和小美（虎斑加白）的实拍照片为参考，使用写实透明精灵图。待机使用实拍参考的独立睡姿：小团蜷睡，小美侧躺伸展。右键点击猫咪切换角色；小团体型更厚实，显示尺寸也更大。

## 功能

- **透明无边框窗口** —— 始终置顶、无标题栏
- **写实白猫素材** —— 使用 `assets/animations/xiaotuan-v2.png` 和 `xiaomei-v2.png` 渲染
- **点击摸摸** —— 单击播放一次短动画，然后回到静止 idle
- **按方向拖拽** —— 拖动窗口时根据鼠标移动方向切换 left/right 行走动画
- **更安静的 idle** —— idle 默认保持静止，不持续眨眼或循环晃动
- **跨平台** —— macOS / Windows / Linux

## 项目结构

```
assets/
└── animations/
    ├── xiaotuan-v2.png     # 小团：4列4行透明精灵图
    └── xiaomei-v2.png      # 小美：4列4行透明精灵图
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

## 发布构建

GitHub Actions 支持通过 tag 或手动触发构建发布版本。

```bash
git tag v0.1.0
git push origin v0.1.0
```

发布流程会上传：

- macOS：`.dmg` 安装包和 `.zip` 应用包
- Windows：`.exe` 安装包和 `.zip` 免安装包
- Linux：`.deb` 安装包和 `.tar.gz` 免安装包

Release note 放在 `release-notes/` 下。比如 `v0.1.0` 会使用 `release-notes/v0.1.0.md`；没有匹配文件时会回退到 `release-notes/default.md`。

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

## Windows 托盘和自动更新

托盘使用项目自有的双猫图标，可显示/隐藏猫咪、切换角色、检查并安装更新、关闭自动更新、退出。关闭窗口时隐藏到托盘。自动更新默认开启，启动15秒后及每4小时检查一次；菜单开关会记住。

更新从 `Token-Rap/MeiTuanDeskPet` 的 GitHub Release 读取 `windows-update.json`，按版本与构建号比较，下载后验证长度及SHA-256，再启动安装器。Windows 可能要求管理员授权，完成安装后自动启动新版。手动检查更新也会下载并安装，不只是打开网页。预览客户端接受预览和正式发布；正式客户端只接受正式发布。

发布流程会从实际安装包生成更新清单，因此发布时应使用项目 workflow 并保留 `windows-update.json` 和安装器。此前的预览1–5没有更新器，需手动安装一次带托盘的新版本。自动升级涉及运行时安装，仍需在实际Windows环境验证完整升级体验。
