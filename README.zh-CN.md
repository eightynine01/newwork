# NewWork

> AI 驱动的编程助手 - 集成桌面应用程序

<p align="center">
  <a href="README.md">English</a> |
  <a href="README.ko.md">한국어</a> |
  <a href="README.zh-CN.md"><b>简体中文</b></a> |
  <a href="README.ja.md">日本語</a>
</p>

[![GitHub stars](https://img.shields.io/github/stars/eightynine01/newwork?style=social)](https://github.com/eightynine01/newwork/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eightynine01/newwork?style=social)](https://github.com/eightynine01/newwork/network/members)
[![GitHub watchers](https://img.shields.io/github/watchers/eightynine01/newwork?style=social)](https://github.com/eightynine01/newwork/watchers)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![Flutter](https://img.shields.io/badge/flutter-3.0+-blue.svg)](https://flutter.dev/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.109+-green.svg)](https://fastapi.tiangolo.com/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

## 📖 概述

**NewWork** 是一款为 Claude Code（前身为 OpenCode）设计的集成桌面 GUI 应用程序。Flutter 前端和 Python 后端被打包成单一可执行文件，安装后无需任何额外设置即可立即使用。

### 核心特性

- 🎯 **一体化应用**: Flutter UI + Python 后端集成为单一可执行文件
- 🚀 **即时启动**: 无需 Docker 或单独的服务器设置
- 💾 **本地优先**: 基于 SQLite 的本地数据存储
- 🖥️ **跨平台**: 支持 Windows、macOS、Linux
- 🔒 **隐私保护**: 所有数据存储在本地

### 主要功能

- 🎯 **会话管理**: 创建、查看和管理 AI 编程会话
- 📝 **模板系统**: 可重用的提示词和工作流程
- 🔧 **技能管理**: AI 代理功能和工具管理
- 📁 **工作区**: 项目组织和管理
- 🔌 **MCP 集成**: Model Context Protocol 服务器支持
- 🌐 **实时通信**: 通过 WebSocket 实现实时流式传输
- 🎨 **Material Design 3**: 现代响应式 UI

## 🏗️ 架构

NewWork 采用完全集成的架构，用户感知不到后端的存在：

```
┌─────────────────────────────────────┐
│   NewWork 桌面应用程序               │
│   (Flutter - 单一可执行文件)          │
│                                     │
│  ┌─────────────┐  ┌──────────────┐ │
│  │   Flutter   │  │   Python     │ │
│  │   UI 层     │◄─┤   后端       │ │
│  │             │  │   (FastAPI)  │ │
│  └─────────────┘  └──────┬───────┘ │
│         │                │         │
│         │         ┌──────▼───────┐ │
│         └────────►│   SQLite DB  │ │
│                   └──────────────┘ │
└─────────────────────────────────────┘
         │
         ▼
   ┌──────────────┐
   │  OpenCode    │
   │  CLI (外部)   │
   └──────────────┘
```

**工作原理**:
1. 用户启动 NewWork 应用
2. 应用启动时自动启动打包的 Python 后端
3. Flutter UI 与 localhost API 通信
4. 应用退出时自动清理后端
5. 所有数据存储在操作系统标准位置

## 🚀 快速开始

### 前置要求

- **开发环境**:
  - Python 3.10+
  - Flutter 3.0+
  - OpenCode CLI（可选）

- **用户（发布版本）**:
  - 无需任何前置要求！只需下载并运行可执行文件。

### 发布版本安装

#### macOS
```bash
# 下载并安装 DMG
open NewWork.dmg
# 拖拽到 Applications 文件夹

# 运行
open /Applications/NewWork.app
```

#### Linux
```bash
# 下载 AppImage
chmod +x NewWork-x86_64.AppImage
./NewWork-x86_64.AppImage

# 或 .deb 包
sudo dpkg -i newwork_0.2.0_amd64.deb
newwork
```

#### Windows
```bash
# 运行 Setup.exe 安装
NewWork-Setup.exe

# 从开始菜单启动
# 或双击桌面图标
```

### 开发环境设置

#### 1. 克隆仓库

```bash
git clone https://github.com/eightynine01/newwork.git
cd newwork
```

#### 2. 后端开发模式

```bash
cd newwork-backend

# 创建并激活虚拟环境
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 安装依赖
pip install -r requirements.txt

# 运行开发服务器
make dev
# 或
uvicorn app.main:app --reload --port 8000
```

后端运行在 `http://localhost:8000`。

API 文档: http://localhost:8000/docs

#### 3. 前端开发模式

```bash
cd newwork-app

# 安装依赖
flutter pub get

# 运行应用（后端必须正在运行）
flutter run -d macos  # 或 linux, windows
```

## 🔄 同类项目比较

| 特性 | NewWork | [OpenWork](https://github.com/different-ai/openwork) | [Moltbot](https://github.com/moltbot/moltbot) |
|------|---------|----------|---------|
| ⭐ GitHub Stars | ![stars](https://img.shields.io/github/stars/eightynine01/newwork?style=social) | ![stars](https://img.shields.io/github/stars/different-ai/openwork?style=social) | ![stars](https://img.shields.io/github/stars/moltbot/moltbot?style=social) |
| 🎯 核心目标 | 集成桌面应用 | 代理工作流 | 个人 AI 助手 |
| 🖥️ 前端 | Flutter | SolidJS + TailwindCSS | Node.js CLI |
| ⚙️ 后端 | FastAPI (Python) | OpenCode CLI (spawned) | TypeScript |
| 📱 移动端 | ✅ (Flutter) | ❌ | ❌ |
| 🚀 安装方式 | 单一可执行文件 | DMG/源码构建 | CLI 安装 |

### 为什么选择 NewWork？

1. **真正的一体化**: 后端完全嵌入应用中，无需单独设置
2. **基于 Flutter**: 易于扩展到移动端，采用 Material Design 3
3. **Python 后端**: 基于 FastAPI 架构，易于扩展和定制
4. **隐私优先**: 所有数据存储在本地，无需外部服务器

## 🤝 贡献

**我们欢迎各种形式的贡献！** 🎉

[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

### 🌟 贡献方式

| 类型 | 说明 |
|------|------|
| 🐛 **Bug 报告** | 发现问题？[提交 issue](https://github.com/eightynine01/newwork/issues/new?template=bug_report.md) |
| 💡 **功能建议** | 有想法？[提出建议](https://github.com/eightynine01/newwork/issues/new?template=feature_request.md) |
| 📝 **文档改进** | 欢迎修正错别字、翻译、添加指南 |
| 🔧 **代码贡献** | 提交 PR！特别欢迎 OpenCode 相关的 PR |
| ⭐ **Star** | 如果喜欢这个项目，请给它一个 Star！ |

### 开发指南

- **代码风格**: Python 使用 Ruff，Dart 使用 `dart format`
- **测试**: 所有 PR 都应包含测试
- **文档**: 新功能需要文档化
- **提交信息**: 推荐使用 [Conventional Commits](https://www.conventionalcommits.org/) 格式

## ☕ 支持我们

如果这个项目对您有帮助，请请我喝杯咖啡！ ☕

<a href="https://www.buymeacoffee.com/newwork" target="_blank">
  <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="50">
</a>

[![PayPal](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/newwork)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/newwork)

## 📄 许可证

本项目采用 MIT 许可证分发。详情请参阅 [LICENSE](LICENSE) 文件。

## 📞 联系与支持

- **问题追踪**: [GitHub Issues](https://github.com/eightynine01/newwork/issues)
- **讨论**: [GitHub Discussions](https://github.com/eightynine01/newwork/discussions)
- **文档**: [docs/](docs/)

---

**Made with ❤️ by the NewWork Team**
