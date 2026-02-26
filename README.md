# LunchTalkSaver - AI 驱动的午休对话屏保

> 一个真正的 macOS Screen Saver，让你的闲置时间充满思考和灵感

## 特色功能

- 🎭 **双角色对话系统**：「发散者」与「落地者」的思维碰撞
- 🤖 **AI 驱动**：支持 OpenAI API 或任何兼容接口（可选）
- 📝 **实时摘要**：自动生成对话要点、灵感和金句
- 🖥️ **真正的屏保**：系统原生 .saver bundle，完美集成
- 🎨 **精美设计**：渐变背景、流畅动画、优雅排版
- ⚙️ **高度可定制**：话题、角色、风格全部可配置

## 快速开始

### 1. 构建 Screen Saver

```bash
# 克隆项目
git clone <your-repo-url>
cd AI_ScreenSaver

# 构建屏保 bundle
./build_saver_xcode.sh

# 安装到系统
cp -r build/LunchTalkSaver.saver ~/Library/Screen\ Savers/
```

### 2. 在系统设置中启用

```bash
# 快速打开屏保设置
./open_screensaver_settings.sh
```

或者手动：
1. 打开「系统设置」→「屏幕保护程序」
2. 在列表中选择「LunchTalk Saver」
3. 配置触发角（推荐：左下角或右下角）

### 3. 开始使用

- 将鼠标移到触发角即可启动屏保
- 移动鼠标或按键即可退出

## 项目结构

```
AI_ScreenSaver/
├── AI_ScreenSaver/              # 主应用和共享代码
│   ├── ScreenSaverPlugin.swift  # Screen Saver 入口类
│   ├── SaverContentView.swift   # 屏保专用 UI（精简版）
│   ├── ContentView.swift        # 主 App UI（完整版）
│   ├── SessionStore.swift       # 共享的对话逻辑
│   ├── HotCornerMonitor.swift   # 触发角监听
│   └── ...
├── build_saver_xcode.sh         # 构建脚本（推荐）
├── build_saver.sh               # 备用构建脚本
├── open_screensaver_settings.sh # 快速打开系统设置
├── SCREENSAVER_BUILD.md         # 详细构建文档
├── USAGE.md                     # 使用指南
└── README.md                    # 本文件
```

## 功能对比

### 主应用 vs Screen Saver

| 功能 | 主应用 | Screen Saver |
|------|--------|-------------|
| 双角色对话 | ✅ | ✅ |
| 实时摘要 | ✅ | ✅ |
| AI 驱动 | ✅ | ✅ |
| 设置面板 | ✅ | ❌ |
| 历史记录 | ✅ | ❌ |
| 多窗口 | ✅ | ❌ |
| 自定义触发角 | ✅ | ❌（使用系统触发角） |
| 系统集成 | 部分 | ✅ 完全集成 |

## 配置说明

### 在主应用中配置

屏保和主应用共享配置（通过 UserDefaults），在主应用中可以设置：

#### 基础设置
- **对话频率**：消息间隔（6-20 秒）
- **显示摘要**：是否在屏保中显示实时摘要
- **退出弹窗**：退出时是否弹出摘要窗口

#### AI 模型
- **API Endpoint**：默认 `https://api.openai.com/v1`
- **Model**：默认 `gpt-4o-mini`
- **API Key**：你的 OpenAI API 密钥
- **最大输出**：单次生成的 token 数量

#### 对话风格
- **思维风格**：偏落地 ↔ 均衡 ↔ 偏发散
- **回复长度**：简短 ↔ 适中 ↔ 详细

#### 话题与角色
- **角色名称**：自定义两个角色的名字
- **角色性格**：默认、批判型、教练型、研究型、乐观型、务实型
- **话题种子**：自定义讨论话题（每行一个）

### 不使用 AI 也可以

如果不配置 API Key，系统会使用内置的模板对话，同样精彩！

## 技术架构

### 核心技术栈

- **SwiftUI**：现代化 UI 框架
- **ScreenSaver.framework**：macOS 原生屏保框架
- **Combine**：响应式编程
- **Swift Package Manager**：构建管理

### 设计模式

- **MVVM**：SessionStore 作为 ViewModel
- **ObservableObject**：状态管理
- **环境对象**：依赖注入
- **模块化**：共享逻辑 + 专用 UI

### 构建流程

1. 创建临时 Swift Package
2. 编译 Swift 源文件为 dylib
3. 打包成 .saver bundle
4. 配置 Info.plist 和 metadata

详见：[SCREENSAVER_BUILD.md](SCREENSAVER_BUILD.md)

## 系统要求

- **macOS**: 14.0 (Sonoma) 或更高
- **架构**: Apple Silicon (arm64)
- **Xcode**: 15.0+ (仅构建时需要)
- **Swift**: 5.9+

## 开发指南

### 本地开发

```bash
# 1. 打开 Xcode 项目
open AI_ScreenSaver.xcodeproj

# 2. 运行主应用进行功能开发和测试
# 选择 AI_ScreenSaver scheme，按 Cmd+R

# 3. 修改屏保相关代码后重新构建
./build_saver_xcode.sh
cp -r build/LunchTalkSaver.saver ~/Library/Screen\ Savers/

# 4. 测试屏保
./open_screensaver_settings.sh
```

### 调试技巧

1. **在主应用中测试**：使用 `ContentView(mode: .saver)` 模拟屏保模式
2. **查看日志**：`log show --predicate 'process == "legacyScreenSaver"' --last 1m`
3. **快速迭代**：修改主应用代码，确认无误后再编译 .saver

### 添加新功能

1. 在 `SessionStore.swift` 中添加共享逻辑
2. 在 `SaverContentView.swift` 中添加屏保 UI
3. 在 `ContentView.swift` 中添加主应用 UI
4. 确保不使用 App-only API（如 `@Environment(\.openWindow)`）

## 故障排除

### 屏保不显示

```bash
# 检查安装
ls -la ~/Library/Screen\ Savers/LunchTalkSaver.saver

# 验证 bundle 完整性
plutil -p ~/Library/Screen\ Savers/LunchTalkSaver.saver/Contents/Info.plist

# 检查可执行文件
file ~/Library/Screen\ Savers/LunchTalkSaver.saver/Contents/MacOS/LunchTalkSaver
```

### 对话不更新

1. 确认 API Key 已配置（如果使用 AI）
2. 检查网络连接
3. 查看控制台错误日志

### 重新安装

```bash
# 清理
rm -rf ~/Library/Screen\ Savers/LunchTalkSaver.saver
rm -rf build/

# 重新构建
./build_saver_xcode.sh
cp -r build/LunchTalkSaver.saver ~/Library/Screen\ Savers/

# 重启系统设置
killall "System Settings"
```

## 路线图

- [x] 基础屏保功能
- [x] AI 对话集成
- [x] 实时摘要
- [x] 用户配置持久化
- [x] 系统触发角支持
- [ ] 更多 AI 模型支持（Anthropic、Gemini 等）
- [ ] 导出对话为 Markdown
- [ ] 主题系统
- [ ] 语音播报（TTS）
- [ ] 多语言支持

## 贡献

欢迎提交 Issue 和 Pull Request！

### 开发约定

- 使用 SwiftLint 保持代码风格
- 提交前测试主应用和屏保
- 更新相关文档

## 许可证

MIT License

## 致谢

- macOS Screen Saver framework
- OpenAI API
- Swift 社区

---

**Made with ❤️ by haoyu**

**Version**: 1.0
**Last Updated**: 2026-02-26
