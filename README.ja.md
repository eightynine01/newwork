# NewWork

> AI搭載コーディングアシスタント - 統合デスクトップアプリケーション

<p align="center">
  <a href="README.md">English</a> |
  <a href="README.ko.md">한국어</a> |
  <a href="README.zh-CN.md">简体中文</a> |
  <a href="README.ja.md"><b>日本語</b></a>
</p>

[![GitHub stars](https://img.shields.io/github/stars/eightynine01/newwork?style=social)](https://github.com/eightynine01/newwork/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eightynine01/newwork?style=social)](https://github.com/eightynine01/newwork/network/members)
[![GitHub watchers](https://img.shields.io/github/watchers/eightynine01/newwork?style=social)](https://github.com/eightynine01/newwork/watchers)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![Flutter](https://img.shields.io/badge/flutter-3.0+-blue.svg)](https://flutter.dev/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.109+-green.svg)](https://fastapi.tiangolo.com/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

## 📖 概要

**NewWork**は、Claude Code（旧OpenCode）向けの統合デスクトップGUIアプリケーションです。FlutterフロントエンドとPythonバックエンドが単一の実行ファイルにバンドルされており、インストール後すぐに追加設定なしで使用できます。

### 主な特徴

- 🎯 **オールインワンアプリケーション**: Flutter UI + Pythonバックエンドが単一実行ファイルに統合
- 🚀 **即時起動**: Dockerや別途サーバー設定不要
- 💾 **ローカルファースト**: SQLiteベースのローカルデータ保存
- 🖥️ **クロスプラットフォーム**: Windows、macOS、Linux対応
- 🔒 **プライバシー重視**: すべてのデータがローカルに保存

### 主要機能

- 🎯 **セッション管理**: AIコーディングセッションの作成、表示、管理
- 📝 **テンプレートシステム**: 再利用可能なプロンプトとワークフロー
- 🔧 **スキル管理**: AIエージェント機能とツール管理
- 📁 **ワークスペース**: プロジェクトの整理と管理
- 🔌 **MCP統合**: Model Context Protocolサーバーサポート
- 🌐 **リアルタイム通信**: WebSocketによるリアルタイムストリーミング
- 🎨 **Material Design 3**: モダンでレスポンシブなUI

## 🏗️ アーキテクチャ

NewWorkは、ユーザーがバックエンドの存在を意識しない完全統合型アーキテクチャを採用しています：

```
┌─────────────────────────────────────┐
│   NewWork デスクトップアプリ          │
│   (Flutter - 単一実行ファイル)        │
│                                     │
│  ┌─────────────┐  ┌──────────────┐ │
│  │   Flutter   │  │   Python     │ │
│  │   UI層      │◄─┤   バックエンド │ │
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

**動作の仕組み**:
1. ユーザーがNewWorkアプリを起動
2. アプリ起動時にバンドルされたPythonバックエンドが自動起動
3. Flutter UIがlocalhost APIと通信
4. アプリ終了時にバックエンドを自動クリーンアップ
5. すべてのデータはOS標準の場所に保存

## 🚀 クイックスタート

### 必要条件

- **開発環境**:
  - Python 3.10以上
  - Flutter 3.0以上
  - OpenCode CLI（オプション）

- **ユーザー（リリース版）**:
  - 必要条件なし！実行ファイルをダウンロードして実行するだけです。

### リリース版インストール

#### macOS
```bash
# DMGをダウンロードしてインストール
open NewWork.dmg
# Applicationsフォルダにドラッグ＆ドロップ

# 実行
open /Applications/NewWork.app
```

#### Linux
```bash
# AppImageをダウンロード
chmod +x NewWork-x86_64.AppImage
./NewWork-x86_64.AppImage

# または.debパッケージ
sudo dpkg -i newwork_0.2.0_amd64.deb
newwork
```

#### Windows
```bash
# Setup.exeを実行してインストール
NewWork-Setup.exe

# スタートメニューから起動
# またはデスクトップアイコンをダブルクリック
```

### 開発環境セットアップ

#### 1. リポジトリをクローン

```bash
git clone https://github.com/eightynine01/newwork.git
cd newwork
```

#### 2. バックエンド開発モード

```bash
cd newwork-backend

# 仮想環境を作成して有効化
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 依存関係をインストール
pip install -r requirements.txt

# 開発サーバーを実行
make dev
# または
uvicorn app.main:app --reload --port 8000
```

バックエンドは `http://localhost:8000` で実行されます。

APIドキュメント: http://localhost:8000/docs

#### 3. フロントエンド開発モード

```bash
cd newwork-app

# 依存関係をインストール
flutter pub get

# アプリを実行（バックエンドが実行中である必要があります）
flutter run -d macos  # またはlinux, windows
```

## 🔄 類似プロジェクト比較

| 特徴 | NewWork | [OpenWork](https://github.com/different-ai/openwork) | [Moltbot](https://github.com/moltbot/moltbot) |
|------|---------|----------|---------|
| ⭐ GitHub Stars | ![stars](https://img.shields.io/github/stars/eightynine01/newwork?style=social) | ![stars](https://img.shields.io/github/stars/different-ai/openwork?style=social) | ![stars](https://img.shields.io/github/stars/moltbot/moltbot?style=social) |
| 🎯 コア目標 | 統合デスクトップアプリ | エージェントワークフロー | パーソナルAIアシスタント |
| 🖥️ フロントエンド | Flutter | SolidJS + TailwindCSS | Node.js CLI |
| ⚙️ バックエンド | FastAPI (Python) | OpenCode CLI (spawned) | TypeScript |
| 📱 モバイル | ✅ (Flutter) | ❌ | ❌ |
| 🚀 インストール方法 | 単一実行ファイル | DMG/ソースビルド | CLIインストール |

### なぜNewWorkなのか？

1. **真のオールインワン**: バックエンドがアプリに完全に内蔵、別途設定不要
2. **Flutterベース**: モバイル拡張が容易でMaterial Design 3を採用
3. **Pythonバックエンド**: FastAPIアーキテクチャで拡張・カスタマイズが容易
4. **プライバシー優先**: すべてのデータがローカルに保存、外部サーバー不要

## 🤝 コントリビューション

**あらゆる形式の貢献を歓迎します！** 🎉

[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

### 🌟 貢献方法

| タイプ | 説明 |
|--------|------|
| 🐛 **バグ報告** | 問題を見つけましたか？[issueを作成](https://github.com/eightynine01/newwork/issues/new?template=bug_report.md) |
| 💡 **機能リクエスト** | アイデアがありますか？[提案してください](https://github.com/eightynine01/newwork/issues/new?template=feature_request.md) |
| 📝 **ドキュメント改善** | タイポ修正、翻訳、ガイド追加すべて歓迎 |
| 🔧 **コード貢献** | PRを送ってください！OpenCode関連のPR特に歓迎 |
| ⭐ **Star** | プロジェクトが気に入ったらStarをお願いします！ |

### 開発ガイドライン

- **コードスタイル**: PythonはRuff、Dartは`dart format`を使用
- **テスト**: すべてのPRにはテストを含める必要があります
- **ドキュメント**: 新機能はドキュメント化が必要です
- **コミットメッセージ**: [Conventional Commits](https://www.conventionalcommits.org/)形式を推奨

## ☕ サポート

このプロジェクトが役に立ったら、コーヒーをおごってください！ ☕

<a href="https://www.buymeacoffee.com/newwork" target="_blank">
  <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="50">
</a>

[![PayPal](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/newwork)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/newwork)

## 📄 ライセンス

このプロジェクトはMITライセンスの下で配布されています。詳細は[LICENSE](LICENSE)ファイルを参照してください。

## 📞 お問い合わせ・サポート

- **Issue Tracker**: [GitHub Issues](https://github.com/eightynine01/newwork/issues)
- **ディスカッション**: [GitHub Discussions](https://github.com/eightynine01/newwork/discussions)
- **ドキュメント**: [docs/](docs/)

---

**Made with ❤️ by the NewWork Team**
