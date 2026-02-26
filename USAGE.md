# LunchTalkSaver 使用指南

## 快速开始

### 1. 构建和安装

```bash
# 在项目根目录运行
./build_saver_xcode.sh

# 安装到系统
cp -r build/LunchTalkSaver.saver ~/Library/Screen\ Savers/
```

### 2. 在系统设置中启用

#### 方法 A：命令行打开（推荐）

```bash
# 直接打开屏幕保护程序设置
open "x-apple.systempreferences:com.apple.preference.desktopscreeneffect"
```

或者：

```bash
# 打开系统设置（通用）
open "x-apple.systempreferences:"
```

#### 方法 B：手动打开

1. 点击  菜单 → 「系统设置」（System Settings）
2. 在左侧栏找到「屏幕保护程序」（Screen Saver）
3. 在屏保列表中找到「LunchTalk Saver」
4. 点击选中

### 3. 配置触发角（可选）

在同一个「屏幕保护程序」设置页面：

1. 找到「触发角」（Hot Corners）按钮
2. 点击进入设置
3. 选择一个角（推荐：左下角或右下角）
4. 在下拉菜单中选择「开始屏幕保护程序」

### 4. 测试运行

#### 通过触发角测试

- 将鼠标移动到设置的触发角
- 屏保应该立即启动

#### 通过预览测试

- 在屏保设置页面，点击「预览」按钮（如果有）
- 或者等待设置的空闲时间

#### 通过快捷键测试（如果已设置）

- macOS 默认没有屏保快捷键
- 可以使用 Automator 或第三方工具创建

### 5. 退出屏保

- **移动鼠标**或**按任意键**即可退出
- 触控板轻触也可以退出

## 功能说明

### 主要功能

1. **双角色对话**
   - 「发散者」（Explorer）：提出创意想法和问题
   - 「落地者」（Builder）：给出具体建议和行动步骤

2. **实时摘要**（可选）
   - 右侧显示对话摘要
   - 包含要点、灵感点、高亮金句
   - 在设置中可开关

3. **AI 驱动**（可选）
   - 支持 OpenAI API 或兼容接口
   - 可配置 API Endpoint、Model、Key
   - 不配置 API Key 则使用内置模板

### 设置项

屏保的设置需要在主 App 中配置：

1. 打开主应用「AI_ScreenSaver.app」
2. 点击「设置」按钮
3. 可配置：
   - **对话节奏**：消息间隔、是否显示摘要
   - **AI 模型**：API 端点、密钥、模型名称
   - **对话风格**：发散程度、回复长度
   - **话题种子**：自定义讨论话题
   - **角色设定**：自定义角色名称和性格

## 系统要求

- **macOS**: 14.0 (Sonoma) 或更高
- **架构**: Apple Silicon (arm64)
- **Xcode**: 15.0+ (仅构建时需要)

## 常见问题

### Q: 为什么屏保列表中没有看到？

A: 尝试以下步骤：
1. 确认安装路径正确：`~/Library/Screen Savers/`（注意是用户目录）
2. 检查 bundle 完整性：`ls -la ~/Library/Screen\ Savers/LunchTalkSaver.saver/Contents/`
3. 重启「系统设置」应用
4. 如果还不行，注销并重新登录

### Q: 屏保启动后是黑屏？

A: 可能原因：
1. **SessionStore 未初始化**：检查日志 `log show --predicate 'process == "legacyScreenSaver"' --last 1m`
2. **SwiftUI 渲染失败**：确保所有依赖框架都已链接
3. **内存不足**：检查系统资源

### Q: 对话内容不更新？

A: 检查：
1. 主 App 中是否配置了 API Key（如果希望使用 AI 功能）
2. 网络连接是否正常
3. 查看控制台是否有 API 错误信息

### Q: 如何自定义话题？

A:
1. 打开主应用「AI_ScreenSaver.app」
2. 进入「设置」→「话题与角色」
3. 在「话题种子」文本框中输入自定义话题（每行一个）
4. 保存后，屏保会随机从这些话题中选择

### Q: 能否不使用 AI，只用内置模板？

A: 可以！只要不配置 API Key，系统会自动使用内置的模板对话。

### Q: 如何卸载？

A:
```bash
rm -rf ~/Library/Screen\ Savers/LunchTalkSaver.saver
```

然后在系统设置中选择其他屏保。

## 高级用法

### 配合主 App 使用

主应用提供更丰富的功能：
- 查看历史对话
- 导出对话摘要
- 自定义触发角监听
- 完整设置面板

### 系统集成

你可以通过以下方式触发屏保：
- **触发角**：最方便，推荐设置
- **Automator**：创建快捷键服务
- **AppleScript**：脚本自动化
- **定时任务**：配合 cron 或 launchd

示例 AppleScript：
```applescript
tell application "System Events"
    start current screen saver
end tell
```

### 与其他工具配合

- **BetterTouchTool**：自定义手势触发
- **Alfred**：创建 Workflow 快速启动
- **Hammerspoon**：Lua 脚本控制

## 技术支持

- 查看完整构建文档：`SCREENSAVER_BUILD.md`
- 查看产品规划：`AI_ScreenSaver/productplan.md`
- 提交问题：项目 GitHub Issues

---

**提示**：首次使用建议先在主 App 中配置好所有设置，然后再启动屏保。屏保和主 App 共享相同的 UserDefaults 配置。
