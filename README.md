# LaSay — Voice Input for Developers

> Dictate in your native language + English technical terms. LaSay keeps them intact.

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![macOS](https://img.shields.io/badge/macOS-13.0+-green)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)

## 功能特色

- **混語言輸入**：母語 + 英文技術術語混著說，輸出保持原樣
- **保留技術術語**：框架、工具、程式碼識別字不被改寫
- **IDE / Terminal 皆可用**：任何 app 的輸入框都能直接貼上
- **全域語音輸入**：按住 **Fn + Space** 即可在任何 app 中錄音
- **AI 文字清理**：移除口語贅字、修正文法與標點
- **即時貼上**：轉錄完成後自動貼到游標位置
- **安全儲存**：API Key 安全加密儲存

## 安裝

1. 下載 `LaSay.dmg`
2. 雙擊開啟，將 LaSay.app 拖到 Applications 資料夾
3. 右鍵點擊 LaSay.app → 選擇「打開」（首次執行需要）

## Quick Start (for Developers)

1. Install LaSay.app → Applications
2. First launch: Grant Microphone + Accessibility permissions
3. Menu bar → Settings → Paste your OpenAI API Key
4. Done. Hold **Fn+Space** anywhere to dictate.

That's it. No account, no signup, no cloud sync. Your API key = your access.

## 設定

### 1. 授予權限

#### 麥克風權限
- **系統設定** → **隱私權與安全性** → **麥克風**
- 勾選 **LaSay**

#### Accessibility 權限（全域快捷鍵）
- **系統設定** → **隱私權與安全性** → **輔助使用**
- 勾選 **LaSay**

### 2. 設定 API Key

1. 點擊 menu bar 的 LaSay 圖示
2. 選擇「設定...」
3. 輸入你的 **OpenAI API Key**
   - 從 [OpenAI Platform](https://platform.openai.com/api-keys) 取得
4. 選擇轉錄語言（繁體中文 / English）
5. （選填）啟用 **AI 文字清理**

## 使用方式

1. 在任何 app 中將游標放在輸入框
2. **按住 Fn + Space**
3. 開始說話
4. **放開 Fn + Space**
5. 文字會自動出現在游標位置

## 費用

LaSay 使用 OpenAI API：
- **Whisper**：約 $0.001 USD / 次
- **GPT-5-mini**（如啟用）：約 $0.00004 USD / 次
- **總計**：約 $0.001-0.002 USD / 次

## 進階設定

- **AI 文字清理**：可開關，使用 GPT-5-mini 優化轉錄文字
- **自訂 Prompt**：自訂 AI 文字清理的行為
- **自動貼上**：可選擇是否自動貼上文字
- **剪貼簿還原**：貼上後可選擇是否還原原剪貼簿內容

## 常見問題

### Q: 為什麼快捷鍵沒反應？
A: 請確認已授予 **Accessibility 權限**，並重新啟動 LaSay。

### Q: Terminal 中無法使用？
A: Terminal 有特殊的鍵盤處理機制，建議在其他 app 使用（如 TextEdit、Chrome、Slack）。

### Q: 轉錄語言不正確？
A: 在設定中選擇正確的語言（繁體中文 / English）。

### Q: 費用會很高嗎？
A: 每次使用約 $0.001-0.002 USD，100 次使用約 $0.10-0.20 USD。

## 授權

此專案為內部使用工具。

## 致謝

- OpenAI Whisper - 語音轉錄
- OpenAI GPT-5-mini - 文字清理
- 開發協助：Claude Sonnet 4.5

---

**版本**：1.0.0
**最後更新**：2026-02-15
