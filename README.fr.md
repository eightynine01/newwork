# NewWork

> Assistant de Programmation IA - Application de Bureau Intégrée

<p align="center">
  <a href="README.md">English</a> |
  <a href="README.ko.md">한국어</a> |
  <a href="README.zh-CN.md">简体中文</a> |
  <a href="README.ja.md">日本語</a> |
  <a href="README.pt-BR.md">Português</a> |
  <a href="README.es.md">Español</a> |
  <a href="README.ru.md">Русский</a> |
  <a href="README.de.md">Deutsch</a> |
  <a href="README.fr.md"><b>Français</b></a>
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

## 📖 Aperçu

**NewWork** est une application GUI de bureau intégrée pour Claude Code (anciennement OpenCode). Le frontend Flutter et le backend Python sont regroupés dans un seul exécutable, permettant une utilisation immédiate après l'installation sans configuration supplémentaire.

### Caractéristiques Principales

- 🎯 **Application Tout-en-Un**: Flutter UI + backend Python intégrés dans un seul exécutable
- 🚀 **Démarrage Instantané**: Pas besoin de Docker ou de configuration serveur séparée
- 💾 **Local-First**: Stockage de données local basé sur SQLite
- 🖥️ **Multiplateforme**: Support Windows, macOS et Linux
- 🔒 **Axé sur la Confidentialité**: Toutes les données stockées localement

### Fonctionnalités Principales

- 🎯 **Gestion des Sessions**: Créer, voir et gérer les sessions de codage IA
- 📝 **Système de Modèles**: Prompts et workflows réutilisables
- 🔧 **Gestion des Compétences**: Capacités des agents IA et gestion des outils
- 📁 **Espace de Travail**: Organisation et gestion des projets
- 🔌 **Intégration MCP**: Support des serveurs Model Context Protocol
- 🌐 **Communication en Temps Réel**: Streaming en temps réel via WebSocket
- 🎨 **Material Design 3**: Interface utilisateur moderne et responsive

## 🏗️ Architecture

NewWork utilise une architecture entièrement intégrée où les utilisateurs ne remarquent pas l'existence du backend:

```
┌─────────────────────────────────────┐
│   NewWork Desktop Application      │
│   (Flutter - Exécutable Unique)     │
│                                     │
│  ┌─────────────┐  ┌──────────────┐ │
│  │   Flutter   │  │   Python     │ │
│  │   Couche UI │◄─┤   Backend    │ │
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

## 🚀 Démarrage Rapide

### Prérequis

- **Environnement de Développement**:
  - Python 3.10+
  - Flutter 3.0+
  - OpenCode CLI (optionnel)

- **Utilisateurs (Version Release)**:
  - Aucun prérequis! Téléchargez et exécutez simplement.

### Installation

#### macOS
```bash
open NewWork.dmg
# Glisser vers le dossier Applications
open /Applications/NewWork.app
```

#### Linux
```bash
chmod +x NewWork-x86_64.AppImage
./NewWork-x86_64.AppImage
```

#### Windows
```bash
# Exécuter NewWork-Setup.exe
```

## 🔄 Comparaison avec des Projets Similaires

| Caractéristique | NewWork | [OpenWork](https://github.com/different-ai/openwork) | [Moltbot](https://github.com/moltbot/moltbot) |
|-----------------|---------|----------|---------|
| ⭐ GitHub Stars | ![stars](https://img.shields.io/github/stars/eightynine01/newwork?style=social) | ![stars](https://img.shields.io/github/stars/different-ai/openwork?style=social) | ![stars](https://img.shields.io/github/stars/moltbot/moltbot?style=social) |
| 🎯 Objectif Principal | App Desktop Intégrée | Workflows d'Agents | Assistant IA Personnel |
| 🖥️ Frontend | Flutter | SolidJS + TailwindCSS | Node.js CLI |
| ⚙️ Backend | FastAPI (Python) | OpenCode CLI | TypeScript |
| 📱 Mobile | ✅ (Flutter) | ❌ | ❌ |
| 🚀 Installation | Exécutable unique | DMG/build source | CLI |

### Pourquoi NewWork?

1. **Vrai Tout-en-Un**: Backend entièrement intégré dans l'app
2. **Basé sur Flutter**: Extension mobile facile avec Material Design 3
3. **Backend Python**: Facile à étendre avec l'architecture FastAPI
4. **Confidentialité d'abord**: Toutes les données stockées localement

## 🤝 Contribuer

**Toutes les formes de contribution sont les bienvenues!** 🎉

[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

| Type | Description |
|------|-------------|
| 🐛 **Rapport de Bug** | Problème trouvé? [Ouvrir une issue](https://github.com/eightynine01/newwork/issues/new?template=bug_report.md) |
| 💡 **Demande de Fonctionnalité** | Une idée? [Suggérer](https://github.com/eightynine01/newwork/issues/new?template=feature_request.md) |
| 📝 **Documentation** | Corrections, traductions, guides bienvenus |
| 🔧 **Code** | Envoyez une PR! |
| ⭐ **Star** | Si vous aimez le projet, donnez une Star! |

## ☕ Soutenir

Si ce projet vous a été utile, offrez-moi un café! ☕

<a href="https://www.buymeacoffee.com/newwork" target="_blank">
  <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="50">
</a>

[![PayPal](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/newwork)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/newwork)

## 📄 Licence

Ce projet est distribué sous la licence MIT. Voir [LICENSE](LICENSE) pour les détails.

## 📞 Contact & Support

- **Issues**: [GitHub Issues](https://github.com/eightynine01/newwork/issues)
- **Discussions**: [GitHub Discussions](https://github.com/eightynine01/newwork/discussions)
- **Documentation**: [docs/](docs/)

---

**Made with ❤️ by the NewWork Team**
