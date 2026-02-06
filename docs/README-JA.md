# ClaudeBar

<p align="center">
  <img src="../assets/icons/claudebar-macOS-Dark-1024x1024@1x.png" alt="ClaudeBar アイコン" width="128" height="128">
</p>

<p align="center">
  <strong>Claude の使用制限をリアルタイムで監視するネイティブ macOS メニューバーアプリ。</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-blue" alt="macOS">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange" alt="Swift">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="ライセンス">
</p>

<p align="center">
  <a href="../README.md">English</a> •
  <a href="README-TR.md">Türkçe</a> •
  <a href="README-ZH.md">中文</a> •
  <a href="README-HI.md">हिन्दी</a> •
  <a href="README-ES.md">Español</a> •
  <a href="README-FR.md">Français</a> •
  <a href="README-AR.md">العربية</a> •
  <a href="README-PT.md">Português</a> •
  <a href="README-JA.md">日本語</a> •
  <a href="README-RU.md">Русский</a> •
  <a href="README-IT.md">Italiano</a>
</p>

> **注意:** この翻訳はAIによって生成されており、誤りや不正確な部分が含まれている可能性があります。修正はPull Requestでお願いします。

---

## 機能

- **リアルタイム使用量監視** - 現在のセッションと週間使用制限を一目で確認
- **プランバッジ** - 現在のサブスクリプションを表示（Pro、Max、Team）
- **追加使用量サポート** - 有効時に従量課金クレジットを追跡
- **カラーコード付きプログレスバー** - 使用率に応じて緑、黄、オレンジ、赤で表示
- **多言語対応** - 英語、トルコ語、中国語、スペイン語、ロシア語、アプリ内言語切替
- **カスタマイズ可能な通知** - 50%、75%、100%、またはリセット時に通知を受信
- **自動更新** - 設定可能な更新間隔（30秒、1分、2分、5分）
- **ログイン時に起動** - オプションでMacと一緒に起動
- **メニューバーにパーセント表示** - メニューバーアイコンの横にパーセントを表示/非表示
- **ネイティブ体験** - SwiftUIで構築、macOSデザインガイドラインに準拠
- **軽量** - リソース使用量が最小限、Electron不使用
- **プライバシー重視** - アナリティクスなし、テレメトリなし

## スクリーンショット

<p align="center">
  <img src="../screenshots/app-screenshot.png" alt="ClaudeBar 概要ビュー" width="380">
</p>

<p align="center">
  <em>プランバッジ付きのリアルタイム使用量監視</em>
</p>

<details>
<summary><strong>その他のスクリーンショット</strong></summary>

<br>

| 設定 | 通知 | 情報 |
|:----:|:----:|:----:|
| <img src="../screenshots/settings-screenshot.png" alt="設定" width="250"> | <img src="../screenshots/notifications-screenshot.png" alt="通知" width="250"> | <img src="../screenshots/about-screenshot.png" alt="情報" width="250"> |

</details>

## 要件

- macOS 14.0（Sonoma）以降
- [Claude Code](https://claude.ai/code) がインストール済みでログイン済みであること
- 有効な Claude Pro、Max、または Team サブスクリプション

## インストール

### Homebrew（推奨）

```bash
brew install --cask kemalasliyuksek/claudebar/claudebar-monitor
```

macOS Gatekeeper のセキュリティを自動的に処理します — 追加の手順は不要です。

### ビルド済みバイナリをダウンロード

[Releases](https://github.com/kemalasliyuksek/claudebar/releases) ページから最新の `.app` をダウンロードし、アプリケーションフォルダにドラッグしてください。

> **注意:** macOS で「ClaudeBar は壊れているため開けません」と表示された場合、以下のコマンドを実行して検疫フラグを削除してください：
> ```bash
> xattr -cr ClaudeBar.app
> ```

### ソースからビルド

```bash
git clone https://github.com/kemalasliyuksek/claudebar.git
cd claudebar
./build.sh
```

アプリバンドルは `.build/release/ClaudeBar.app` に作成されます。

インストール：
```bash
cp -r .build/release/ClaudeBar.app /Applications/
```

## 使い方

1. Claude Code にログインしていることを確認してください（ターミナルで `claude` コマンドが動作すること）
2. アプリケーションまたは Spotlight から ClaudeBar を起動
3. メニューバーのゲージアイコンをクリックして使用制限を表示

### 設定

⚙️ アイコンをクリックして設定：

| 設定 | 説明 |
|------|------|
| ログイン時に起動 | ログイン時に自動的に起動 |
| メニューバーに%表示 | メニューバーアイコンの横にパーセントを表示 |
| 言語 | アプリの言語を選択（システム、English、Türkçe、中文、Español、Русский） |
| 更新間隔 | 使用データの取得頻度（30秒〜5分） |
| 50%で通知 | 使用量50%で通知を送信 |
| 75%で通知 | 使用量75%で通知を送信 |
| 制限到達時に通知 | 制限に達した時に通知を送信 |
| リセット時に通知 | 制限がリセットされた時に通知を送信 |

### 情報

ⓘ アイコンをクリックしてアプリ情報、クレジット、リンクを表示。

## 仕組み

ClaudeBar は、Claude Code がログイン時に保存する OAuth 認証情報を macOS キーチェーンから読み取ります。その後、Anthropic API に問い合わせて現在の使用制限を取得します。

### アーキテクチャ

```
┌─────────────────┐                      ┌───────────────────────────┐
│                 │  Stores tokens       │                           │
│   Claude Code   │─────────────────────▶│     macOS Keychain        │
│   (CLI login)   │                      │ "Claude Code-credentials" │
└─────────────────┘                      └───────────────────────────┘
                                                     │
                                                     │ Reads tokens
                                                     ▼
┌─────────────────┐                      ┌───────────────────────────┐
│                 │ GET /api/oauth/usage │                           │
│  Anthropic API  │◀─────────────────────│        ClaudeBar          │
│                 │─────────────────────▶│                           │
└─────────────────┘    Usage data        └───────────────────────────┘
```

## 重要な注意事項

### キーチェーンアクセス

初回起動時、macOS が ClaudeBar のキーチェーンへのアクセスを許可するよう求める場合があります。スムーズな動作のために **常に許可** をクリックしてください。

### プライバシー

- キーチェーンの既存の認証情報のみを読み取ります
- すべての通信はHTTPSを使用
- システムキーチェーン以外にデータは保存されません
- アナリティクスやテレメトリなし
- 完全オープンソース

## コントリビューション

コントリビューションを歓迎します！お気軽に Pull Request を送信してください。

1. リポジトリをフォーク
2. フィーチャーブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. Pull Request を開く

## ライセンス

このプロジェクトは MIT ライセンスの下でライセンスされています - 詳細は [LICENSE](../LICENSE) ファイルをご覧ください。

## 作者

**Kemal Aslıyüksek** - [@kemalasliyuksek](https://github.com/kemalasliyuksek)

## 免責事項

これは非公式のコミュニティプロジェクトであり、Anthropic とは提携しておらず、Anthropic によって公式にメンテナンスまたは承認されていません。ご自身の判断でご使用ください。
