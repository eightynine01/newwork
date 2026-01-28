# NewWork

> AI-ассистент для программирования - Интегрированное десктопное приложение

<p align="center">
  <a href="README.md">English</a> |
  <a href="README.ko.md">한국어</a> |
  <a href="README.zh-CN.md">简体中文</a> |
  <a href="README.ja.md">日本語</a> |
  <a href="README.pt-BR.md">Português</a> |
  <a href="README.es.md">Español</a> |
  <a href="README.ru.md"><b>Русский</b></a> |
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

## 📖 Обзор

**NewWork** — это интегрированное GUI-приложение для Claude Code (ранее OpenCode). Flutter-фронтенд и Python-бэкенд упакованы в единый исполняемый файл, что позволяет использовать приложение сразу после установки без дополнительной настройки.

### Ключевые особенности

- 🎯 **Всё-в-одном**: Flutter UI + Python бэкенд в едином исполняемом файле
- 🚀 **Мгновенный запуск**: Не требуется Docker или отдельная настройка сервера
- 💾 **Локальное хранение**: Хранение данных на базе SQLite
- 🖥️ **Кроссплатформенность**: Поддержка Windows, macOS, Linux
- 🔒 **Приватность**: Все данные хранятся локально

### Основные функции

- 🎯 **Управление сессиями**: Создание, просмотр и управление AI-сессиями кодирования
- 📝 **Система шаблонов**: Переиспользуемые промпты и рабочие процессы
- 🔧 **Управление навыками**: Возможности AI-агентов и управление инструментами
- 📁 **Рабочие пространства**: Организация и управление проектами
- 🔌 **Интеграция MCP**: Поддержка серверов Model Context Protocol
- 🌐 **Реальное время**: Потоковая передача через WebSocket
- 🎨 **Material Design 3**: Современный и отзывчивый UI

## 🏗️ Архитектура

NewWork использует полностью интегрированную архитектуру, где пользователи не замечают существования бэкенда:

```
┌─────────────────────────────────────┐
│   NewWork Desktop Application      │
│   (Flutter - Единый исполняемый)    │
│                                     │
│  ┌─────────────┐  ┌──────────────┐ │
│  │   Flutter   │  │   Python     │ │
│  │   UI слой   │◄─┤   Бэкенд     │ │
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
   │  CLI (внеш.) │
   └──────────────┘
```

## 🚀 Быстрый старт

### Требования

- **Среда разработки**:
  - Python 3.10+
  - Flutter 3.0+
  - OpenCode CLI (опционально)

- **Пользователи (Релизная версия)**:
  - Никаких требований! Просто скачайте и запустите.

### Установка

#### macOS
```bash
open NewWork.dmg
# Перетащите в папку Applications
open /Applications/NewWork.app
```

#### Linux
```bash
chmod +x NewWork-x86_64.AppImage
./NewWork-x86_64.AppImage
```

#### Windows
```bash
# Запустите NewWork-Setup.exe
```

## 🔄 Сравнение с похожими проектами

| Характеристика | NewWork | [OpenWork](https://github.com/different-ai/openwork) | [Moltbot](https://github.com/moltbot/moltbot) |
|----------------|---------|----------|---------|
| ⭐ GitHub Stars | ![stars](https://img.shields.io/github/stars/eightynine01/newwork?style=social) | ![stars](https://img.shields.io/github/stars/different-ai/openwork?style=social) | ![stars](https://img.shields.io/github/stars/moltbot/moltbot?style=social) |
| 🎯 Основная цель | Интегрированное приложение | Агентные workflow | Персональный AI-ассистент |
| 🖥️ Фронтенд | Flutter | SolidJS + TailwindCSS | Node.js CLI |
| ⚙️ Бэкенд | FastAPI (Python) | OpenCode CLI | TypeScript |
| 📱 Мобильный | ✅ (Flutter) | ❌ | ❌ |
| 🚀 Установка | Единый исполняемый | DMG/сборка из исходников | CLI |

### Почему NewWork?

1. **Настоящий Всё-в-одном**: Бэкенд полностью встроен в приложение
2. **На базе Flutter**: Легкое расширение на мобильные с Material Design 3
3. **Python бэкенд**: Легко расширять с архитектурой FastAPI
4. **Приватность прежде всего**: Все данные хранятся локально

## 🤝 Вклад в проект

**Приветствуются все формы участия!** 🎉

[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

| Тип | Описание |
|-----|----------|
| 🐛 **Баг-репорт** | Нашли проблему? [Создайте issue](https://github.com/eightynine01/newwork/issues/new?template=bug_report.md) |
| 💡 **Запрос функции** | Есть идея? [Предложите](https://github.com/eightynine01/newwork/issues/new?template=feature_request.md) |
| 📝 **Документация** | Исправления, переводы, руководства приветствуются |
| 🔧 **Код** | Отправьте PR! |
| ⭐ **Звезда** | Если проект понравился, поставьте Star! |

## ☕ Поддержка

Если проект был полезен, угостите меня кофе! ☕

<a href="https://www.buymeacoffee.com/newwork" target="_blank">
  <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="50">
</a>

[![PayPal](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/newwork)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/newwork)

## 📄 Лицензия

Этот проект распространяется под лицензией MIT. См. [LICENSE](LICENSE) для деталей.

## 📞 Контакты и поддержка

- **Issues**: [GitHub Issues](https://github.com/eightynine01/newwork/issues)
- **Обсуждения**: [GitHub Discussions](https://github.com/eightynine01/newwork/discussions)
- **Документация**: [docs/](docs/)

---

**Made with ❤️ by the NewWork Team**
