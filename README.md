# Forests

自分のペースで森に暮らす、**オリジナル3Dスローライフ**（iPhone / App Store 目標）。

既存作品のキャラ・名称・マップ・UI・音楽は使用しません。

## いまの状態（MVP 進行中）

| 項目 | 状態 |
|---|---|
| エンジン | **Godot 4.3**（選定理由は `docs/TECH_DECISION.md`） |
| プレイアブル核 | 3Dフィールド歩行・採取・インベントリ・セーブ |
| iOS実機ビルド | **Mac + Xcode が必要**（`docs/IOS_EXPORT.md`） |
| 家具・家・NPC | **未実装**（フェーズ2以降） |

Web Canvas の初期実験は `archive/web-canvas-prototype/` に保管（本線ではない）。

## ドキュメント

- [`docs/TECH_DECISION.md`](docs/TECH_DECISION.md) — 調査・エンジン選定・リスク
- [`docs/MVP_PLAN.md`](docs/MVP_PLAN.md) — 画面・操作・ディレクトリ・フェーズ
- [`docs/IOS_EXPORT.md`](docs/IOS_EXPORT.md) — 実機・提出手順

## 開発の開き方

```bash
# Godot 4.3 で
godot --path godot
```

または Godot Editor で `godot/project.godot` を開く。

### 操作（横画面）

- **左下スティック** … 移動
- **右スワイプ** … カメラ
- **タップ** … 調べる
- **採る** … 素材取得
- **かばん / 設定 / 記録**

## コンセプト差分（参考）

どうぶつの森的な「スローライフ」体験を目指しつつ、世界観・システムは独自。  
将来（フェーズ2+）では **生きた家具（配置が生態に効く）** などを本家と差別化する予定。

## ライセンス（アセット）

MVPの見た目はすべて **エンジン組み込みプリミティブの自作配置**。  
外部キャラクター・音楽・テクスチャは未導入。追加時はライセンスを必ず記録すること。
