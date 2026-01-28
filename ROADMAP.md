# NewWork Roadmap

> Detailed release plan and development milestones

<p align="center">
  <a href="ROADMAP.md"><b>English</b></a> |
  <a href="ROADMAP.ko.md">한국어</a>
</p>

## 📍 Current Status

**Version**: 0.2.0 (Development)
**Stage**: Alpha
**Target**: v1.0.0 Production Release

---

## 🎯 Release Schedule

```
2026 Q1 ─────────────────────────────────────────────────────►
         │
    v0.2.0 ◄── Current (Jan)
         │
    v0.2.1 ─── Bug fixes & Polish (Feb)
         │
    v0.3.0 ─── Core Enhancement (Mar)

2026 Q2 ─────────────────────────────────────────────────────►
         │
    v0.4.0 ─── Collaboration (Apr)
         │
    v0.5.0 ─── Plugin System (May)
         │
    v1.0.0 ─── Production Release (Jun)
```

---

## 📦 Version Details

### v0.2.0 - Integrated App (Current)

**Status**: 🟡 In Progress
**Target Date**: January 2026

#### Completed ✅
- [x] Project rename (OpenWork → NewWork)
- [x] Python backend standalone executable (PyInstaller)
- [x] Error recovery system with exponential backoff
- [x] Health monitoring and auto-restart
- [x] Auto-update checking (GitHub Releases)
- [x] Multilingual README (EN, KO, ZH, JA)
- [x] GitHub repository setup

#### In Progress 🔄
- [ ] Flutter app backend integration testing
- [ ] Cross-platform build pipeline
- [ ] First release deployment (macOS, Linux, Windows)

#### Blocked 🔴
- [ ] Code signing for macOS/Windows (requires certificates)

---

### v0.2.1 - Bug Fixes & Polish

**Status**: ⚪ Planned
**Target Date**: February 2026

#### Goals
- [ ] Fix critical bugs from v0.2.0 feedback
- [ ] Improve UI/UX based on user feedback
- [ ] Performance optimization
- [ ] Documentation improvements

#### Tasks
| Task | Priority | Status |
|------|----------|--------|
| Fix backend startup issues on Windows | High | ⬜ |
| Improve error messages | Medium | ⬜ |
| Add loading states for all async operations | Medium | ⬜ |
| Optimize SQLite queries | Low | ⬜ |
| Update API documentation | Medium | ⬜ |

---

### v0.3.0 - Core Enhancement

**Status**: ⚪ Planned
**Target Date**: March 2026

#### Goals
- Enhanced session management
- Template library with sharing
- Dark/Light theme support
- Keyboard shortcuts

#### Features
| Feature | Description | Priority |
|---------|-------------|----------|
| Session Search | Full-text search across sessions | High |
| Session Export | Export to Markdown/JSON/PDF | High |
| Template Categories | Organize templates by category | Medium |
| Theme System | Dark/Light/System theme | High |
| Keyboard Navigation | Vim-like keybindings option | Medium |
| Session Tags | Tag and filter sessions | Low |

#### Technical Debt
- [ ] Refactor state management
- [ ] Add comprehensive logging
- [ ] Improve test coverage to 80%

---

### v0.4.0 - Collaboration Features

**Status**: ⚪ Planned
**Target Date**: April 2026

#### Goals
- Workspace sharing (local network)
- Template import/export
- Cloud backup (optional)

#### Features
| Feature | Description | Priority |
|---------|-------------|----------|
| Local Sharing | Share workspaces over LAN | High |
| Template Export | Export/import template packs | High |
| iCloud/Google Drive | Optional cloud backup | Medium |
| Team Templates | Shared template library | Medium |

---

### v0.5.0 - Plugin System

**Status**: ⚪ Planned
**Target Date**: May 2026

#### Goals
- Plugin architecture
- Community plugin marketplace
- Custom AI provider support

#### Features
| Feature | Description | Priority |
|---------|-------------|----------|
| Plugin API | Stable plugin development API | High |
| Plugin Manager | In-app plugin installation | High |
| Custom Providers | Support for OpenAI, local LLMs | High |
| Plugin Marketplace | Community plugin repository | Medium |

---

### v1.0.0 - Production Release

**Status**: ⚪ Planned
**Target Date**: June 2026

#### Goals
- Feature complete
- Comprehensive documentation
- Auto-update system
- Community support infrastructure

#### Release Checklist
- [ ] All planned features implemented
- [ ] Test coverage > 85%
- [ ] Performance benchmarks passed
- [ ] Security audit completed
- [ ] Documentation complete (EN, KO, ZH, JA)
- [ ] Auto-update tested on all platforms
- [ ] Community Discord/Forum setup
- [ ] Landing page live

---

## 🔮 Future Roadmap (Post v1.0)

### v1.1.0 - Mobile Support
- iOS app
- Android app
- Cross-device sync

### v1.2.0 - Enterprise Features
- Team management
- SSO integration
- Audit logs

### v2.0.0 - AI Evolution
- Multi-model conversations
- AI agent marketplace
- Custom training support

---

## 📊 Metrics & Goals

### GitHub Goals

| Milestone | Stars | Target Date |
|-----------|-------|-------------|
| First 100 ⭐ | 100 | Feb 2026 |
| Trending | 500 | Mar 2026 |
| 1K Club | 1,000 | Apr 2026 |
| Popular | 5,000 | Jun 2026 |
| Viral | 10,000 | 2026 EOY |

### Quality Metrics

| Metric | Target | Current |
|--------|--------|---------|
| Test Coverage | > 85% | ~60% |
| Build Success Rate | > 99% | TBD |
| Issue Response Time | < 24h | TBD |
| PR Merge Time | < 7 days | TBD |

---

## 🤝 How to Contribute

We welcome contributions at any stage! See our priorities:

### High Priority (v0.2.x)
- Bug reports and fixes
- Documentation improvements
- Translation contributions

### Medium Priority (v0.3.x)
- Feature implementations
- UI/UX improvements
- Test coverage improvements

### Open for Discussion
- Plugin API design
- New feature proposals
- Architecture improvements

---

## 📅 Weekly Progress Updates

Progress updates are posted in:
- [GitHub Discussions](https://github.com/eightynine01/newwork/discussions)
- [CHANGELOG.md](CHANGELOG.md)

---

**Last Updated**: January 2026

---

*This roadmap is subject to change based on community feedback and priorities.*
