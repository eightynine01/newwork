# NewWork

> Asistente de Codificación con IA - Aplicación de Escritorio Integrada

<p align="center">
  <a href="README.md">English</a> |
  <a href="README.ko.md">한국어</a> |
  <a href="README.zh-CN.md">简体中文</a> |
  <a href="README.ja.md">日本語</a> |
  <a href="README.pt-BR.md">Português</a> |
  <a href="README.es.md"><b>Español</b></a> |
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

## 📖 Descripción General

**NewWork** es una aplicación GUI de escritorio integrada para Claude Code (anteriormente OpenCode). El frontend Flutter y el backend Python están empaquetados en un único ejecutable, permitiendo su uso inmediato después de la instalación sin ninguna configuración adicional.

### Características Clave

- 🎯 **Aplicación Todo-en-Uno**: Flutter UI + backend Python integrados en un único ejecutable
- 🚀 **Inicio Instantáneo**: Sin necesidad de Docker o configuración de servidor separada
- 💾 **Local-First**: Almacenamiento local de datos basado en SQLite
- 🖥️ **Multiplataforma**: Soporte para Windows, macOS y Linux
- 🔒 **Enfoque en Privacidad**: Todos los datos almacenados localmente

### Funcionalidades Principales

- 🎯 **Gestión de Sesiones**: Crear, ver y gestionar sesiones de codificación con IA
- 📝 **Sistema de Plantillas**: Prompts y flujos de trabajo reutilizables
- 🔧 **Gestión de Habilidades**: Capacidades de agentes IA y gestión de herramientas
- 📁 **Espacio de Trabajo**: Organización y gestión de proyectos
- 🔌 **Integración MCP**: Soporte para servidores Model Context Protocol
- 🌐 **Comunicación en Tiempo Real**: Streaming en tiempo real vía WebSocket
- 🎨 **Material Design 3**: UI moderna y responsiva

## 🏗️ Arquitectura

NewWork utiliza una arquitectura completamente integrada donde los usuarios no perciben la existencia del backend:

```
┌─────────────────────────────────────┐
│   NewWork Desktop Application      │
│   (Flutter - Ejecutable Único)      │
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

## 🚀 Inicio Rápido

### Prerrequisitos

- **Entorno de Desarrollo**:
  - Python 3.10+
  - Flutter 3.0+
  - OpenCode CLI (opcional)

- **Usuarios (Versión de Lanzamiento)**:
  - ¡Sin prerrequisitos! Solo descarga y ejecuta.

### Instalación

#### macOS
```bash
open NewWork.dmg
# Arrastra a la carpeta Applications
open /Applications/NewWork.app
```

#### Linux
```bash
chmod +x NewWork-x86_64.AppImage
./NewWork-x86_64.AppImage
```

#### Windows
```bash
# Ejecuta NewWork-Setup.exe
```

## 🔄 Comparación con Proyectos Similares

| Característica | NewWork | [OpenWork](https://github.com/different-ai/openwork) | [Moltbot](https://github.com/moltbot/moltbot) |
|----------------|---------|----------|---------|
| ⭐ GitHub Stars | ![stars](https://img.shields.io/github/stars/eightynine01/newwork?style=social) | ![stars](https://img.shields.io/github/stars/different-ai/openwork?style=social) | ![stars](https://img.shields.io/github/stars/moltbot/moltbot?style=social) |
| 🎯 Objetivo Principal | App de Escritorio Integrada | Flujos de Agentes | Asistente IA Personal |
| 🖥️ Frontend | Flutter | SolidJS + TailwindCSS | Node.js CLI |
| ⚙️ Backend | FastAPI (Python) | OpenCode CLI | TypeScript |
| 📱 Móvil | ✅ (Flutter) | ❌ | ❌ |
| 🚀 Instalación | Ejecutable único | DMG/compilar fuente | CLI |

### ¿Por qué NewWork?

1. **Verdadero Todo-en-Uno**: Backend completamente integrado en la app
2. **Basado en Flutter**: Fácil expansión móvil con Material Design 3
3. **Backend Python**: Fácil de extender con arquitectura FastAPI
4. **Privacidad Primero**: Todos los datos almacenados localmente

## 🤝 Contribuir

**¡Todas las formas de contribución son bienvenidas!** 🎉

[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

| Tipo | Descripción |
|------|-------------|
| 🐛 **Bug Report** | ¿Encontraste un problema? [Abre un issue](https://github.com/eightynine01/newwork/issues/new?template=bug_report.md) |
| 💡 **Feature Request** | ¿Tienes una idea? [Sugiérela](https://github.com/eightynine01/newwork/issues/new?template=feature_request.md) |
| 📝 **Documentación** | Correcciones, traducciones, guías son bienvenidas |
| 🔧 **Código** | ¡Envía un PR! |
| ⭐ **Star** | Si te gusta el proyecto, ¡dale una Star! |

## ☕ Apoya

Si este proyecto te fue útil, ¡invítame un café! ☕

<a href="https://www.buymeacoffee.com/newwork" target="_blank">
  <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="50">
</a>

[![PayPal](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/newwork)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/newwork)

## 📄 Licencia

Este proyecto está distribuido bajo la Licencia MIT. Ver [LICENSE](LICENSE) para detalles.

## 📞 Contacto y Soporte

- **Issues**: [GitHub Issues](https://github.com/eightynine01/newwork/issues)
- **Discusiones**: [GitHub Discussions](https://github.com/eightynine01/newwork/discussions)
- **Documentación**: [docs/](docs/)

---

**Made with ❤️ by the NewWork Team**
