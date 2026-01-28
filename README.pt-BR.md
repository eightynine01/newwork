# NewWork

> Assistente de Codificação com IA - Aplicativo Desktop Integrado

<p align="center">
  <a href="README.md">English</a> |
  <a href="README.ko.md">한국어</a> |
  <a href="README.zh-CN.md">简体中文</a> |
  <a href="README.ja.md">日本語</a> |
  <a href="README.pt-BR.md"><b>Português</b></a> |
  <a href="README.es.md">Español</a> |
  <a href="README.ru.md">Русский</a> |
  <a href="README.de.md">Deutsch</a> |
  <a href="README.fr.md">Français</a>
</p>

[![GitHub stars](https://img.shields.io/github/stars/eightynine01/newwork?style=social)](https://github.com/eightynine01/newwork/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eightynine01/newwork?style=social)](https://github.com/eightynine01/newwork/network/members)
[![GitHub watchers](https://img.shields.io/github/watchers/eightynine01/newwork?style=social)](https://github.com/eightynine01/newwork/watchers)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![Flutter](https://img.shields.io/badge/flutter-3.0+-blue.svg)](https://flutter.dev/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.109+-green.svg)](https://fastapi.tiangolo.com/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

<!-- Star History Chart -->
<a href="https://star-history.com/#eightynine01/newwork&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=eightynine01/newwork&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=eightynine01/newwork&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=eightynine01/newwork&type=Date" />
 </picture>
</a>

## 📖 Visão Geral

**NewWork** é um aplicativo GUI de desktop integrado para Claude Code (anteriormente OpenCode). O frontend Flutter e o backend Python são empacotados em um único executável, permitindo uso imediato após a instalação sem nenhuma configuração adicional.

### Características Principais

- 🎯 **Aplicativo Tudo-em-Um**: Flutter UI + backend Python integrados em um único executável
- 🚀 **Início Instantâneo**: Sem necessidade de Docker ou configuração de servidor separada
- 💾 **Local-First**: Armazenamento local de dados baseado em SQLite
- 🖥️ **Multiplataforma**: Suporte para Windows, macOS e Linux
- 🔒 **Foco em Privacidade**: Todos os dados armazenados localmente

### Funcionalidades Principais

- 🎯 **Gerenciamento de Sessões**: Criar, visualizar e gerenciar sessões de codificação com IA
- 📝 **Sistema de Templates**: Prompts e workflows reutilizáveis
- 🔧 **Gerenciamento de Skills**: Capacidades de agentes IA e gerenciamento de ferramentas
- 📁 **Workspace**: Organização e gerenciamento de projetos
- 🔌 **Integração MCP**: Suporte a servidores Model Context Protocol
- 🌐 **Comunicação em Tempo Real**: Streaming em tempo real via WebSocket
- 🎨 **Material Design 3**: UI moderna e responsiva

## 🏗️ Arquitetura

NewWork usa uma arquitetura totalmente integrada onde os usuários não percebem a existência do backend:

```
┌─────────────────────────────────────┐
│   NewWork Desktop Application      │
│   (Flutter - Executável Único)      │
│                                     │
│  ┌─────────────┐  ┌──────────────┐ │
│  │   Flutter   │  │   Python     │ │
│  │   UI Layer  │◄─┤   Backend    │ │
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
   │  CLI (ext.)  │
   └──────────────┘
```

## 🚀 Início Rápido

### Pré-requisitos

- **Ambiente de Desenvolvimento**:
  - Python 3.10+
  - Flutter 3.0+
  - OpenCode CLI (opcional)

- **Usuários (Versão de Release)**:
  - Sem pré-requisitos! Apenas baixe e execute.

### Instalação

#### macOS
```bash
open NewWork.dmg
# Arraste para a pasta Applications
open /Applications/NewWork.app
```

#### Linux
```bash
chmod +x NewWork-x86_64.AppImage
./NewWork-x86_64.AppImage
```

#### Windows
```bash
# Execute NewWork-Setup.exe
```

## 🔄 Comparação com Projetos Similares

| Característica | NewWork | [OpenWork](https://github.com/different-ai/openwork) | [Moltbot](https://github.com/moltbot/moltbot) |
|----------------|---------|----------|---------|
| ⭐ GitHub Stars | ![stars](https://img.shields.io/github/stars/eightynine01/newwork?style=social) | ![stars](https://img.shields.io/github/stars/different-ai/openwork?style=social) | ![stars](https://img.shields.io/github/stars/moltbot/moltbot?style=social) |
| 🎯 Objetivo Principal | App Desktop Integrado | Workflows de Agentes | Assistente IA Pessoal |
| 🖥️ Frontend | Flutter | SolidJS + TailwindCSS | Node.js CLI |
| ⚙️ Backend | FastAPI (Python) | OpenCode CLI | TypeScript |
| 📱 Mobile | ✅ (Flutter) | ❌ | ❌ |
| 🚀 Instalação | Executável único | DMG/build de fonte | CLI |

### Por que NewWork?

1. **Verdadeiro Tudo-em-Um**: Backend totalmente embutido no app
2. **Baseado em Flutter**: Fácil expansão mobile com Material Design 3
3. **Backend Python**: Fácil de estender com arquitetura FastAPI
4. **Privacidade Primeiro**: Todos os dados armazenados localmente

## 🤝 Contribuindo

**Todas as formas de contribuição são bem-vindas!** 🎉

[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

| Tipo | Descrição |
|------|-----------|
| 🐛 **Bug Report** | Encontrou um problema? [Abra uma issue](https://github.com/eightynine01/newwork/issues/new?template=bug_report.md) |
| 💡 **Feature Request** | Tem uma ideia? [Sugira](https://github.com/eightynine01/newwork/issues/new?template=feature_request.md) |
| 📝 **Documentação** | Correções, traduções, guias são bem-vindos |
| 🔧 **Código** | Envie um PR! |
| ⭐ **Star** | Se gostou do projeto, dê uma Star! |

## ☕ Apoie

Se este projeto foi útil, me pague um café! ☕

<a href="https://www.buymeacoffee.com/newwork" target="_blank">
  <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="50">
</a>

[![PayPal](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/newwork)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/newwork)

## 📄 Licença

Este projeto é distribuído sob a Licença MIT. Veja [LICENSE](LICENSE) para detalhes.

## 📞 Contato & Suporte

- **Issues**: [GitHub Issues](https://github.com/eightynine01/newwork/issues)
- **Discussões**: [GitHub Discussions](https://github.com/eightynine01/newwork/discussions)
- **Documentação**: [docs/](docs/)

---

**Made with ❤️ by the NewWork Team**
