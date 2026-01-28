# NewWork

> KI-gestützter Programmierassistent - Integrierte Desktop-Anwendung

<p align="center">
  <a href="README.md">English</a> |
  <a href="README.ko.md">한국어</a> |
  <a href="README.zh-CN.md">简体中文</a> |
  <a href="README.ja.md">日本語</a> |
  <a href="README.pt-BR.md">Português</a> |
  <a href="README.es.md">Español</a> |
  <a href="README.ru.md">Русский</a> |
  <a href="README.de.md"><b>Deutsch</b></a> |
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

## 📖 Übersicht

**NewWork** ist eine integrierte Desktop-GUI-Anwendung für Claude Code (früher OpenCode). Das Flutter-Frontend und das Python-Backend sind in einer einzigen ausführbaren Datei gebündelt, sodass Sie es sofort nach der Installation ohne zusätzliche Konfiguration verwenden können.

### Hauptmerkmale

- 🎯 **Alles-in-Einem**: Flutter UI + Python-Backend in einer einzigen Datei
- 🚀 **Sofortiger Start**: Kein Docker oder separate Server-Einrichtung erforderlich
- 💾 **Local-First**: SQLite-basierte lokale Datenspeicherung
- 🖥️ **Plattformübergreifend**: Unterstützung für Windows, macOS und Linux
- 🔒 **Datenschutz-fokussiert**: Alle Daten werden lokal gespeichert

### Hauptfunktionen

- 🎯 **Sitzungsverwaltung**: KI-Coding-Sitzungen erstellen, anzeigen und verwalten
- 📝 **Vorlagensystem**: Wiederverwendbare Prompts und Workflows
- 🔧 **Skill-Verwaltung**: KI-Agenten-Fähigkeiten und Tool-Verwaltung
- 📁 **Arbeitsbereich**: Projektorganisation und -verwaltung
- 🔌 **MCP-Integration**: Model Context Protocol Server-Unterstützung
- 🌐 **Echtzeit-Kommunikation**: Echtzeit-Streaming über WebSocket
- 🎨 **Material Design 3**: Moderne und responsive Benutzeroberfläche

## 🏗️ Architektur

NewWork verwendet eine vollständig integrierte Architektur, bei der Benutzer das Backend nicht bemerken:

```
┌─────────────────────────────────────┐
│   NewWork Desktop Application      │
│   (Flutter - Einzelne Datei)        │
│                                     │
│  ┌─────────────┐  ┌──────────────┐ │
│  │   Flutter   │  │   Python     │ │
│  │   UI-Schicht│◄─┤   Backend    │ │
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

## 🚀 Schnellstart

### Voraussetzungen

- **Entwicklungsumgebung**:
  - Python 3.10+
  - Flutter 3.0+
  - OpenCode CLI (optional)

- **Benutzer (Release-Version)**:
  - Keine Voraussetzungen! Einfach herunterladen und ausführen.

### Installation

#### macOS
```bash
open NewWork.dmg
# In den Applications-Ordner ziehen
open /Applications/NewWork.app
```

#### Linux
```bash
chmod +x NewWork-x86_64.AppImage
./NewWork-x86_64.AppImage
```

#### Windows
```bash
# NewWork-Setup.exe ausführen
```

## 🔄 Vergleich mit ähnlichen Projekten

| Merkmal | NewWork | [OpenWork](https://github.com/different-ai/openwork) | [Moltbot](https://github.com/moltbot/moltbot) |
|---------|---------|----------|---------|
| ⭐ GitHub Stars | ![stars](https://img.shields.io/github/stars/eightynine01/newwork?style=social) | ![stars](https://img.shields.io/github/stars/different-ai/openwork?style=social) | ![stars](https://img.shields.io/github/stars/moltbot/moltbot?style=social) |
| 🎯 Hauptziel | Integrierte Desktop-App | Agenten-Workflows | Persönlicher KI-Assistent |
| 🖥️ Frontend | Flutter | SolidJS + TailwindCSS | Node.js CLI |
| ⚙️ Backend | FastAPI (Python) | OpenCode CLI | TypeScript |
| 📱 Mobil | ✅ (Flutter) | ❌ | ❌ |
| 🚀 Installation | Einzelne Datei | DMG/Quellcode-Build | CLI |

### Warum NewWork?

1. **Echtes Alles-in-Einem**: Backend vollständig in die App eingebettet
2. **Flutter-basiert**: Einfache mobile Erweiterung mit Material Design 3
3. **Python-Backend**: Leicht erweiterbar mit FastAPI-Architektur
4. **Datenschutz zuerst**: Alle Daten werden lokal gespeichert

## 🤝 Mitwirken

**Alle Formen der Mitwirkung sind willkommen!** 🎉

[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

| Typ | Beschreibung |
|-----|--------------|
| 🐛 **Bug-Report** | Problem gefunden? [Issue erstellen](https://github.com/eightynine01/newwork/issues/new?template=bug_report.md) |
| 💡 **Feature-Anfrage** | Idee? [Vorschlagen](https://github.com/eightynine01/newwork/issues/new?template=feature_request.md) |
| 📝 **Dokumentation** | Korrekturen, Übersetzungen, Anleitungen willkommen |
| 🔧 **Code** | PR einreichen! |
| ⭐ **Star** | Gefällt das Projekt? Gib einen Star! |

## ☕ Unterstützung

Wenn dieses Projekt nützlich war, spendiere mir einen Kaffee! ☕

<a href="https://www.buymeacoffee.com/newwork" target="_blank">
  <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="50">
</a>

[![PayPal](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/newwork)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/newwork)

## 📄 Lizenz

Dieses Projekt wird unter der MIT-Lizenz verteilt. Siehe [LICENSE](LICENSE) für Details.

## 📞 Kontakt & Support

- **Issues**: [GitHub Issues](https://github.com/eightynine01/newwork/issues)
- **Diskussionen**: [GitHub Discussions](https://github.com/eightynine01/newwork/discussions)
- **Dokumentation**: [docs/](docs/)

---

**Made with ❤️ by the NewWork Team**
