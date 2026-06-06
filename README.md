# LingoPin-AHK

> LingoPin 是一款基于 AutoHotkey v2 开发的轻量级屏幕取词贴图与就地文本翻译工具。系统深度兼容 Windows 环境，支持多翻译接口调度与自定义大模型（LLM）API 接入，提供高保真的中英双向文本翻译、格式化恢复与排版重组。

<p align="center">
  <img src="assets/settings.png" width="380" alt="LingoPin Settings GUI" style="border-radius: 6px; box-shadow: 0 2px 6px rgba(0,0,0,0.15);">
</p>

<p align="center">
  <a href="https://github.com/123cz789/LingoPin-AHK/releases/latest"><img src="https://img.shields.io/badge/Download-LingoPin.exe%20(绿色免安装版)-green?style=for-the-badge&logo=windows" alt="Download LingoPin.exe"></a>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/123cz789/LingoPin-AHK" alt="License"></a>
  <a href="https://www.autohotkey.com/"><img src="https://img.shields.io/badge/AutoHotkey-v2.0+-orange.svg" alt="AHK Version"></a>
  <img src="https://img.shields.io/badge/DLP-Anti--Watermark-blue" alt="DLP Clean">
</p>

---

## 1. 系统设计与工作流 (System Architecture)

LingoPin 采用模块化、低耦合的“数据-视图”分离架构。系统通过挂钩 Windows 剪贴板，在不破坏用户原生剪贴板数据的原则下，实现文本的提取、清洗、翻译与呈现。

### 1.1 业务数据流向 (Data Flow)

```text
[选中文本] -> [模拟 Ctrl+C] -> [Windows 剪贴板接管与安全备份]
                                             |
                                             v
[格式化与去水印] <- [双核翻译引擎调度(API)] <- [安全 JSON 字符转义]
       |
       +---> (只读场景) 贴图翻译模式 -> [生成免激活/置顶/可拉伸卡片]
       |
       +---> (可写场景) 输入转写模式 -> [模拟 Ctrl+V 覆盖] -> [还原备份剪贴板]
```

### 1.2 系统分层设计
- **控制层（Controller）：** 采用 `Hotkey()` 函数动态监听。支持在运行时动态绑定、修改或注销系统全局热键。
- **数据层（Data）：** 内置双核高可用调度算法。首选支持标准 OpenAI 格式的本地/远程大语言模型（LLM）；自带网络断路保护器，在 API 异常或断网时自动降级为公共翻译通道。
- **安全过滤层（Security）：** 基于 PCRE 正则表达式引擎。自动检测并秒级剔除部分网页防复制机制暗中注入的 32 位 MD5 追踪混淆字符。
- **视图层（View）：** 基于 Win32 GUI 架构，采用无边框设计。通过接管 Windows 消息泵（`OnMessage`）拦截 `WM_LBUTTONDOWN` 与 `WM_LBUTTONDBLCLK`，实现卡片的“任意位置拖动”与“双击销毁”，有效防止多开贴图时发生内存泄漏。

---

## 2. 功能特性 (Features)

- **置顶贴图翻译（读屏模式）**：选中任意文本，通过快捷键在当前鼠标位置生成常驻置顶、无边框的翻译卡片（基于 Win32 GUI 开发）。支持鼠标拖拽移动、双击关闭，以及边缘拉伸动态自适应缩放。
- **就地文本替换（编辑模式）**：在任意可编辑文本域中选中文本，通过快捷键直接将原文翻译并就地替换，适用于快速起草英文邮件、文档或代码注释。
- **多接口与大模型接入**：默认免配置直连公共翻译接口；支持配置符合 OpenAI 标准的自定义大模型接口（如 DeepSeek、Kimi 等），通过提示词（Prompt）约束实现高质量的信达雅翻译。
- **自定义提示词（Prompt）**：设置面板内置多种学术论文、日常口语、技术文档等翻译预设，支持用户完全自定义翻译提示词。
- **剪贴板干扰字符清洗**：针对部分网页在复制时强制植入的 32 位 MD5 等追踪加密字符或混淆文本，系统会在内存层自动利用正则引擎进行清洗，防止翻译和排版错乱。
- **长文本分块传输**：针对公共接口单次请求的字数限制，系统后台会自动按段落执行文本切片和并行重组，支持长文本稳定翻译。
- **图形化设置面板**：通过系统托盘菜单可调出 GUI 设置界面，支持快捷键自定义或热键动态注销。

---

## 3. 系统要求 (System Requirements)

| 属性 (Property) | 兼容性规范 (Specification) |
| :--- | :--- |
| **支持的系统 (Supported OS)** | **仅限 Windows 系统** (Windows 7 / 10 / 11) |
| **不支持的平台 (Unsupported)** | macOS / Linux / ChromeOS / iOS / Android |
| **系统底层依赖** | 深度依赖 Windows 内核与 Win32 API 消息机制 |
| **免安装绿色版 (.exe)** | **双击直接运行** (完全免安装任何环境) |
| **源码编译运行 (.ahk)** | 必须预先安装 [AutoHotkey v2.0+](https://www.autohotkey.com/) 运行环境 |

---

## 4. 安装与使用 (Installation & Usage)

### 4.1 运行方法
- **源码版**：下载本项目中的 `LingoPin.ahk`。双击运行即可，任务栏右下角会出现放大镜图标。
- **免安装版**：前往本仓库的 [Releases 页面](https://github.com/123cz789/LingoPin-AHK/releases) 下载最新版的 `LingoPin.exe` 绿色单文件版，双击直接运行。

### 4.2 默认快捷键 (Default Hotkeys)
- **`Ctrl + Shift + T`**：触发“贴图翻译”（鼠标任意位置按住可拖拽移动，双击卡片任意位置关闭，拖拽右下角边缘拉伸工作区）。
- **`Ctrl + Shift + R`**：触发“就地转写替换”。

### 4.3 配置管理 (Settings)
右键点击任务栏右下角小图标 -> 选择 **【设置面板】**。
- 可自定义两个模式的专属快捷键，或点击“清空”来关闭它。
- 在“大模型配置”板块，可以接入任何兼容 OpenAI 格式的大模型接口。

---

## 5. 大模型 API 接入指南 (LLM API Guide)

本工具支持将翻译质量无损升级为人工智能大模型级别，如果您有服务商提供的 API 密钥，可在【设置面板】中配置：

1. **国内直连大模型（以阿里云百炼平台 Qwen 为例）：**
   - **接口地址**：`https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions`
   - **API 密钥**：`填入您申请的百炼 sk-xxxxxx 密钥`
   - **模型名称**：`qwen-plus`
2. **DeepSeek 官方 API：**
   - **接口地址**：`https://api.deepseek.com/v1/chat/completions`
   - **API 密钥**：`填入您的 deepseek 密钥`
   - **模型名称**：`deepseek-chat`

---

## 6. 贡献与维护 (Contributing)

我们欢迎任何形式的 Issue 和 Pull Request。
由于项目采用 AHK v2 的严格编译模式，任何提交的代码请确保通过 `#Warn` 验证。

## 7. 开源协议 (License)

本项目基于 [MIT License](LICENSE) 协议开源。
```
