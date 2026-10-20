# iOS 実機ビルド・App Store 手順（Godot 4.3）

本クラウド環境は **Linux** のため、iPhone向けバイナリは作れません。  
以下は **Mac + Xcode** での作業です。

## 前提

- macOS（最新に近いもの）
- [Godot 4.3](https://godotengine.org/download)（プロジェクトと同メジャー）
- Xcode（App Store）
- Apple Developer Program（実機・提出に必要）
- 本リポジトリの `godot/` フォルダ

## 1. プロジェクトを開く

1. Godot で `godot/project.godot` を開く  
2. エディタで **はじめる** → 横画面でスティック移動・採集を確認  
3. Project → Project Settings → Display → Window → Handheld Orientation が Landscape

## 2. iOS エクスポートテンプレート

1. Editor → Manage Export Templates → Download / Install（4.3 用）  
2. Project → Export → Add… → **iOS**  
3. 署名: Team ID / Bundle Identifier（例: `com.yourname.forests`）を設定  
4. Export Project で Xcode プロジェクトを出力

## 3. Xcode

1. 生成された `.xcodeproj` / workspace を開く  
2. Signing & Capabilities で Team を選択  
3. 実機を接続し Run  
4. 確認項目:
   - 仮想スティックで歩行
   - 右スワイプでカメラ
   - 木/花タップ → 採る → かばんに入る
   - 記録 → アプリ再起動 → つづきからで位置・所持・採集状態が残る
   - ノッチ / Dynamic Island でボタンが隠れないこと

## 4. パフォーマンス確認（必須）

- Instruments でメモリ・熱
- 古い端末（可能なら iPhone 11 世代）でも 30fps 以上を目標
- 影・fog を落とす設定を Settings に後続追加予定

## 5. App Store（フェーズ5）

MVPでは提出しない。提出時に必要なもの:

- アプリアイコン / スクリーンショット
- Privacy Manifest（トラッキングなしでも現状の要件に合わせる）
- 年齢レーティング・説明文（オリジナル作品である旨）

## いま実装済み / 未実装

| 済み（MVP核） | 未実装（完成扱いしない） |
|---|---|
| 3D小マップ・歩行・カメラ | 家・家具配置 |
| タッチ操作・採取・インベントリ | 釣り・栽培・NPC |
| 設定・チュートリアル | 本格昼夜・天候経済 |
| JSONセーブ/ロード | App Store提出一式 |
