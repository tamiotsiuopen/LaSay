# LaSay

給開發者的語音輸入工具。用母語口述，夾雜英文技術術語 -- LaSay 原封不動保留。

[English](README.md)

## 為什麼需要 LaSay

開發者用混合語言思考。你用中文說「幫我 refactor 那個 useEffect hook」，所有語音工具都會把 useEffect 轉成亂碼。LaSay 內建 300+ 技術術語字典加上 AI 後處理，框架名稱、程式碼識別字、技術用語全部原樣保留。

**按住 Fn+Space，說話，放開，文字出現在游標。**

任何 app 都能用 -- VS Code、Terminal、Slack、瀏覽器，任何有輸入框的地方。

## 功能

- **混語言轉錄** -- 母語 + 英文技術術語混著說
- **300+ 術語保留** -- React、FastAPI、Kubernetes、camelCase 識別字全部保留
- **雙轉錄模式** -- 雲端（OpenAI Whisper API）或本地（whisper.cpp，完全離線）
- **AI 文字清理** -- 去贅字、修文法、保留術語（GPT-5-mini）
- **全域快捷鍵** -- Fn+Space 在任何 app 都能用
- **即時貼上** -- 轉錄完成的瞬間，文字出現在游標位置
- **安全儲存** -- API Key 存在 macOS Keychain

## 快速開始

```
1. 安裝 LaSay.app 到 /Applications
2. 首次啟動授予麥克風 + 輔助使用權限
3. Menu bar → 設定 → 輸入 OpenAI API Key
4. 在任何地方按住 Fn+Space 開始口述
```

不用註冊。不用登入。不用雲端同步。你的 API Key，你的資料。

## 架構

```
Fn+Space（按住）
    │
    ▼
AudioRecorder（16kHz mono AAC）
    │
    ├─► 雲端：OpenAI Whisper API ──► 轉錄
    │
    └─► 本地：whisper.cpp CLI ─────► 轉錄
                                       │
                                       ▼
                                TechTermsDictionary
                                （300+ regex 術語修正）
                                       │
                                       ▼
                                AI 清理（選配）
                                GPT-5-mini 文字潤飾
                                       │
                                       ▼
                                自動貼上至游標
```

## 轉錄模式比較

| 模式 | 引擎 | 延遲 | 費用 | 離線 |
|------|------|------|------|------|
| 雲端 | OpenAI Whisper API | ~1-2 秒 | ~$0.001/次 | 否 |
| 本地 | whisper.cpp (ggml-base) | ~2-4 秒 | 免費 | 是 |

本地模式首次使用時自動下載 whisper.cpp 執行檔和 ggml-base 模型（約 142MB）。

## 設定

### 權限

LaSay 需要兩個 macOS 權限：

- **麥克風** -- 系統設定 > 隱私權與安全性 > 麥克風
- **輔助使用** -- 系統設定 > 隱私權與安全性 > 輔助使用（全域快捷鍵需要）

### 設定選項

從 menu bar 圖示 > 設定進入：

- **轉錄模式** -- 雲端或本地
- **轉錄語言** -- 自動 / 中文 / 英文 / 日文 / 韓文
- **AI 文字清理** -- 開關切換，支援自訂 prompt
- **API Key** -- 雲端模式和 AI 清理需要

### API Key

雲端模式和 AI 文字清理需要 API Key。從 [platform.openai.com/api-keys](https://platform.openai.com/api-keys) 取得。

存在 macOS Keychain，不是 UserDefaults，不是明文檔案。

## 費用

使用雲端模式 + AI 清理：

| 項目 | 每次費用 |
|------|---------|
| Whisper API | ~$0.001 |
| GPT-5-mini（如啟用） | ~$0.00004 |
| **合計** | **~$0.001** |

每天 100 次 ≈ 每月 $3 美元。本地模式免費。

## 支援語言

轉錄：自動偵測、中文（zh）、英文（en）、日文（ja）、韓文（ko）

介面：繁體中文、English

## 常見問題

**快捷鍵沒反應？**
授予輔助使用權限後需要重啟 LaSay。這是 macOS 的限制。

**Terminal 能用嗎？**
可以，透過模擬 Cmd+V 貼上。部分終端模擬器可能需要額外設定。

**術語修正準確嗎？**
字典涵蓋 300+ 術語，橫跨主要程式語言（Python、JavaScript、TypeScript、Swift、Rust、Java、C/C++/C#）、框架（React、FastAPI、Django、Spring）、資料庫（PostgreSQL、MongoDB、Redis）、DevOps 工具（Docker、Kubernetes、Terraform）及常見縮寫（API、SDK、CI/CD、ORM）。

**不用 API Key 能用嗎？**
可以。切換到本地模式，whisper.cpp 完全在你的電腦上跑。AI 文字清理需要 API Key。

**API Key 存在哪？**
macOS Keychain（透過 Security framework）。不在 UserDefaults，不在明文檔案。

## 系統需求

- macOS 13.0（Ventura）或更新
- Apple Silicon 或 Intel Mac
- 網路連線（僅雲端模式）
- OpenAI API Key（雲端模式和 AI 清理）

---

[Tamio Tsiu](mailto:tamio.tsiu@gmail.com)
