# VoiceScribe

## macOS 系統級語音輸入工具

---

## 1. 專案概述

VoiceScribe 是一款 macOS 原生的系統級語音輸入工具。用戶可以在任何應用程式的任何輸入框中，透過快捷鍵觸發語音輸入，即時將語音轉換為文字並自動插入到當前游標位置。

**核心差異化**：內建 AI 文字潤飾功能，自動優化口語表達、移除贅字、修正文法，這是現有競品沒有的功能。

---

## 2. 核心功能

### 2.1 基本功能

- **全域快捷鍵觸發**：用戶按住指定快捷鍵（可以自定義）開始錄音
- **即時語音錄製**：透過系統麥克風捕捉語音
- **語音轉文字**：使用 OpenAI Whisper API 進行高精度語音識別
- **自動文字插入**：將轉換後的文字自動貼到當前應用程式的輸入框中
- **視覺反饋**：錄音狀態的即時提示（menu bar icon 變化）

### 2.2 進階功能（差異化優勢）

- **AI 文字潤飾**：使用 Claude API 對轉錄文字進行優化
  - 移除口語贅字（「呃」、「那個」、「就是」）
  - 修正文法錯誤
  - 根據 context 調整成通順流暢的字句，包含標點符號。

---

## 3. 技術架構

### 3.1 開發環境

| 項目 | 規格 |
|------|------|
| 開發語言 | Swift 5.9+ |
| UI 框架 | SwiftUI |
| 系統整合 | AppKit |
| 最低系統要求 | macOS 13.0 (Ventura) |
| 開發工具 | Xcode 15+ |

### 3.2 應用程式形式

Menu Bar Application（常駐應用），不佔用 Dock 空間，僅在 menu bar 顯示圖示。

### 3.3 外部服務依賴

| 服務 | 用途 | 備註 |
|------|------|------|
| OpenAI Whisper API | 語音轉文字 | 主要轉錄引擎 |
| OpenAI API | 文字潤飾 | 使用 gpt-5-mini 模型 |

### 3.4 系統權限需求

- **麥克風權限**：錄製語音（必要）
- **Accessibility 權限**：監聽全域快捷鍵、模擬鍵盤輸入（必要）

---

## 4. 功能模組

### 4.1 Menu Bar UI 模組

- 顯示應用程式狀態圖示（待機 / 錄音中 / 處理中）
- 下拉選單：設定、關於、結束
- 錄音時顯示動態波形或紅點指示

### 4.2 快捷鍵監聽模組

- 全域監聽指定快捷鍵
- 支援 Press-and-Hold 模式（按住開始、放開結束）
- 支援自訂快捷鍵

### 4.3 錄音模組

- 使用 AVFoundation 錄製音訊
- 輸出格式：m4a 或 wav（Whisper API 相容格式）
- 暫存於臨時目錄，處理完成後刪除

### 4.4 語音轉文字模組

- 呼叫 OpenAI Whisper API
- 支援多語言（初期：繁體中文、英文）
- 處理 API 錯誤與重試機制

### 4.5 文字潤飾模組

- 呼叫 Open API 優化文字
- 可透過設定開關啟用/停用
- 預設 prompt 可自訂

### 4.6 文字輸入模組

- 將結果寫入系統剪貼簿
- 模擬 ⌘V 貼上到當前游標位置
- 選項：貼上後自動還原原本剪貼簿內容

### 4.7 設定模組

- API Keys 管理（OpenAI）
- 快捷鍵設定
- 語言偏好設定
- AI 潤飾開關與 prompt 自訂
- 開機自動啟動選項

---

## 5. 用戶體驗流程

1. 用戶在任何應用中（Slack、Email、Google Docs、Terminal 等）將游標置於輸入框
2. 按住預設快捷鍵
3. Menu bar icon 變為錄音狀態（紅色）
4. 用戶說話
5. 放開快捷鍵，停止錄音
6. Menu bar icon 變為處理中狀態
7. 文字自動出現在游標位置（目標 < 3 秒）
8. 用戶可以繼續編輯或直接使用

---

## 6. 技術挑戰與解決方案

| 挑戰 | 解決方案 |
|------|----------|
| 延遲優化 | 串流處理、API 選擇優化、本地快取 |
| 術語識別 | Whisper prompt 提示、後處理校正 |
| 權限處理 | 清晰的首次啟動引導流程 |
| 穩定性 | 完善的錯誤處理、離線降級機制 |
| 多語言 | 初期專注中英文，後續擴展 |

---

## 7. 專案結構

```
VoiceScribe/
├── VoiceScribeApp.swift          # App entry point
├── AppDelegate.swift              # Menu bar setup
├── Models/
│   └── AppState.swift             # 應用狀態管理
├── Views/
│   ├── MenuBarView.swift          # Menu bar UI
│   └── SettingsView.swift         # 設定視窗
├── Services/
│   ├── AudioRecorder.swift        # 錄音服務
│   ├── WhisperService.swift       # Whisper API 串接
│   ├── OpenAIService.swift        # OpenAI API 串接
│   ├── HotkeyManager.swift        # 快捷鍵監聽
│   └── TextInputService.swift     # 剪貼簿與模擬輸入
├── Utilities/
│   └── KeychainHelper.swift       # API Key 安全儲存
└── Resources/
    └── Assets.xcassets            # 圖示資源
```

---

## 8. 成功指標

- **產品**：完成可售版本的 macOS app
- **用戶**：至少 10 位付費用戶
- **收入**：USD 300-1,500
- **學習**：掌握 Swift/macOS 開發基礎
- **個人使用**：成為自己日常工作流程的一部分

---

## 9. 未來擴展方向

- 本地語音識別選項（Apple Speech Framework 或 Whisper.cpp）
- 多場景模式（Email / Code / Casual）
- Windows/Linux 版本
- 企業版本（團隊共享設定、自定義 prompts）
