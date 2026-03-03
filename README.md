# AI-ScreenSaver (LunchTalk Saver)

一个可安装到 macOS 的 `.saver` 屏保插件。  
当前仓库以 **LunchTalk Saver** 为唯一可用构建目标。

---

## 1) 一键安装（推荐）

在项目根目录执行：

```bash
./install_saver.command
```

这个脚本会自动：

1. 构建最新 `LunchTalkSaver.saver`
2. 删除旧测试插件（`NetworkProof` / `ProofV3`）
3. 安装到 `~/Library/Screen Savers/LunchTalkSaver.saver`
4. 刷新屏保进程并打开系统屏保设置页

然后在系统设置里选择 **LunchTalk Saver** 并点「预览」。

---

## 2) API Key 本地配置（不再硬编码）

支持 3 种来源，按优先级读取：

1. App 内设置（`apiKey`）
2. 环境变量 `OPENAI_API_KEY`
3. 本地文件 `~/.ai-screensaver.env`

### 方式 A：环境变量（临时）

```bash
export OPENAI_API_KEY='你的key'
./install_saver.command
```

### 方式 B：本地配置文件（推荐）

创建 `~/.ai-screensaver.env`：

```bash
cat > ~/.ai-screensaver.env <<'EOF'
OPENAI_API_KEY=你的key
EOF
chmod 600 ~/.ai-screensaver.env
```

然后执行：

```bash
./install_saver.command
```

---

## 3) 常见问题

### Q1: 显示 `API调用失败(no-api-key)`
说明没有读到 key。请检查：

- `~/.ai-screensaver.env` 是否存在
- 文件内容是否是 `OPENAI_API_KEY=...`
- 是否有多余空格或引号

### Q2: 显示 `API调用失败(status: xxx)`
说明请求到达了服务器，但被拒绝或异常返回（常见 401/429）。

### Q3: 屏保黑屏/不全屏
请先重新安装：

```bash
./install_saver.command
```

再退出并重开「系统设置 -> 屏幕保护程序」。

---

## 4) 构建产物

- 构建目录：`/tmp/LunchTalkSaver_build/LunchTalkSaver.saver`
- 安装目录：`~/Library/Screen Savers/LunchTalkSaver.saver`

---

## 5) 项目最小结构

- `AI_ScreenSaver/ScreenSaverPlugin.swift`：屏保入口
- `AI_ScreenSaver/SaverContentView.swift`：屏保 UI
- `AI_ScreenSaver/SessionStore.swift`：对话与 API 请求逻辑
- `build_saver.sh`：构建脚本
- `install_saver.command`：安装脚本

---

## 安全说明

- 仓库中已移除硬编码 API Key。
- 建议仅使用本地环境变量或本地文件存储密钥。
- 不要把 `~/.ai-screensaver.env` 提交到 Git。
