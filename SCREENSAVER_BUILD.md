# LunchTalkSaver - macOS Screen Saver Build Guide

## 概述

这个项目包含一个真正的 macOS Screen Saver bundle（.saver），可以在「系统设置 → 屏幕保护程序」中选择并使用。

## 构建说明

### 自动构建（推荐）

运行项目根目录的构建脚本：

```bash
./build_saver_xcode.sh
```

这个脚本会：
1. 创建临时 Swift Package
2. 编译 Screen Saver 源文件
3. 生成 `build/LunchTalkSaver.saver` bundle
4. 输出安装指令

### 手动安装

构建完成后，复制到用户的 Screen Savers 目录：

```bash
cp -r build/LunchTalkSaver.saver ~/Library/Screen\ Savers/
```

### 验证安装

```bash
ls -la ~/Library/Screen\ Savers/LunchTalkSaver.saver
```

应该看到完整的 bundle 结构：
```
LunchTalkSaver.saver/
  Contents/
    Info.plist
    MacOS/
      LunchTalkSaver (可执行文件)
    Resources/
```

## 使用说明

### 1. 在系统设置中启用

1. 打开「系统设置」（System Settings）
2. 前往「屏幕保护程序」（Screen Saver）
3. 在列表中找到并选择「LunchTalk Saver」
4. 可选：设置触发角（Hot Corners）

### 2. 触发屏保

可以通过以下方式触发：
- **系统触发角**：在「系统设置 → 桌面与屏幕保护程序 → 触发角」中设置
- **快捷键**：系统默认或自定义快捷键
- **空闲时间**：在屏保设置中配置自动启动时间

### 3. 退出屏保

- 移动鼠标
- 按任意键
- 触碰触控板

## 架构说明

### 核心文件

1. **ScreenSaverPlugin.swift**
   - 继承自 `ScreenSaverView`
   - 负责初始化和生命周期管理
   - 主类：`LunchTalkScreenSaverView`

2. **SaverContentView.swift**
   - 专为 Screen Saver 设计的 SwiftUI 视图
   - 精简版，去掉了 App-only 的依赖（如 `openWindow`）
   - 包含对话列表和摘要面板

3. **SessionStore.swift**
   - 共享的对话逻辑和状态管理
   - 同时被主 App 和 Screen Saver 使用

### 与主 App 的区别

| 特性 | 主 App (ContentView) | Screen Saver (SaverContentView) |
|------|---------------------|----------------------------------|
| 设置面板 | ✅ 完整设置 | ❌ 无 |
| 历史记录 | ✅ 可查看 | ❌ 无 |
| 窗口管理 | ✅ 多窗口 | ❌ 单视图 |
| 触发角 | ✅ 自定义监听 | ❌ 系统管理 |
| 对话功能 | ✅ | ✅ |
| 实时摘要 | ✅ | ✅ |

## Bundle 结构

### Info.plist 关键字段

```xml
<key>NSPrincipalClass</key>
<string>LunchTalkScreenSaverView</string>
```

这告诉 macOS 使用 `LunchTalkScreenSaverView` 作为屏保的入口类。

### CFBundlePackageType

```xml
<key>CFBundlePackageType</key>
<string>BNDL</string>
```

标识这是一个 Bundle，而不是普通的 Application。

## 故障排除

### 屏保不出现在列表中

1. 检查 bundle 是否完整：
   ```bash
   plutil -p ~/Library/Screen\ Savers/LunchTalkSaver.saver/Contents/Info.plist
   ```

2. 验证可执行文件：
   ```bash
   file ~/Library/Screen\ Savers/LunchTalkSaver.saver/Contents/MacOS/LunchTalkSaver
   ```
   应该显示：`Mach-O 64-bit dynamically linked shared library arm64`

3. 重启「系统设置」应用

### 屏保崩溃或无法启动

1. 查看控制台日志：
   ```bash
   log show --predicate 'process == "legacyScreenSaver"' --last 1m
   ```

2. 检查是否缺少依赖的框架

3. 确保 API Key 已配置（如果使用 AI 功能）

### 重新构建

如果需要重新构建：

```bash
# 清理旧版本
rm -rf ~/Library/Screen\ Savers/LunchTalkSaver.saver
rm -rf build/

# 重新构建和安装
./build_saver_xcode.sh
cp -r build/LunchTalkSaver.saver ~/Library/Screen\ Savers/
```

## 开发说明

### 修改源码后重新构建

1. 编辑 `AI_ScreenSaver/SaverContentView.swift` 或其他源文件
2. 运行 `./build_saver_xcode.sh`
3. 重新安装：`cp -r build/LunchTalkSaver.saver ~/Library/Screen\ Savers/`
4. 在系统设置中测试

### 添加新功能

如果要添加新功能：
- 在 `SessionStore.swift` 中添加共享逻辑
- 在 `SaverContentView.swift` 中添加 UI
- **注意**：不要使用 `@Environment(\.openWindow)` 等 App-only API

### 调试

Screen Saver 调试比较困难，建议：
1. 先在主 App 中测试功能（使用 `ContentView(mode: .saver)`）
2. 确认无误后再编译 .saver bundle
3. 使用 `print()` 输出调试信息（在控制台查看）

## 技术细节

### 编译过程

1. 创建临时 Swift Package
2. 使用 `swift build -c release` 编译
3. 生成 `libLunchTalkSaver.dylib`
4. 复制到 bundle 的 `Contents/MacOS/` 并重命名
5. 使用 `install_name_tool` 修正动态库加载路径

### 为什么不直接用 Xcode target？

- 在 Xcode 中手动创建 Screen Saver target 需要修改复杂的 `.pbxproj` 文件
- Swift Package Manager 更轻量，构建脚本更易维护
- 避免了 SDK 版本冲突问题

## 许可证

与主项目相同。

---

**构建时间**：2026-02-26
**兼容系统**：macOS 14.0+ (Apple Silicon)
