# LaSay

## macOS 系統級語音輸入工具

---

## 1. 專案概述

LaSay 是一款 macOS 原生的系統級語音輸入工具。用戶可以在任何應用程式的任何輸入框中，透過快捷鍵觸發語音輸入，即時將語音轉換為文字並自動插入到當前游標位置。

**核心差異化**：內建 AI 文字潤飾功能，自動優化口語表達、移除贅字、修正文法，這是現有競品沒有的功能。

---

## 2. 核心功能

### 2.1 基本功能

- **全域快捷鍵觸發**：按住 **Fn + Space** 開始錄音（放開停止）
- **即時語音錄製**：透過系統麥克風捕捉語音
- **語音轉文字**：使用 OpenAI Whisper API 進行高精度語音識別（支援繁體中文和英文）
- **自動文字插入**：將轉換後的文字自動貼到當前應用程式的輸入框中
- **視覺反饋**：錄音狀態的即時提示
  - 待機：灰色麥克風圖示
  - 錄音中：紅色麥克風圖示（閃爍動畫）
  - 處理中：藍色波形圖示（旋轉動畫）

### 2.2 進階功能（差異化優勢）

- **AI 文字潤飾**：使用 GPT-5-mini 對轉錄文字進行優化
  - 移除口語贅字（「呃」、「那個」、「就是」）
  - 修正文法錯誤
  - 根據 context 調整成通順流暢的字句，包含標點符號
  - 可自訂 System Prompt
  - 可選擇啟用或停用

- **剪貼簿管理**：
  - 自動貼上選項（可開關）
  - 貼上後自動還原原剪貼簿內容（可開關）

---

## 3. 技術架構

### 3.1 技術棧

- **語言**：Swift
- **UI 框架**：SwiftUI + AppKit（Menu Bar App）
- **音訊處理**：AVFoundation (AVAudioRecorder)
- **全域快捷鍵**：CGEvent（Event Tap）
- **API 整合**：
  - OpenAI Whisper API（語音轉錄）
  - OpenAI GPT-5-mini（文字潤飾）
- **安全儲存**：加密儲存（API Key）
- **權限管理**：
  - 麥克風權限（AVCaptureDevice）
  - Accessibility 權限（全域快捷鍵監聽）

### 3.2 專案結構

```
LaSay/
├── VoiceScribe/VoiceScribe/
│   ├── VoiceScribeApp.swift          # App entry point
│   ├── AppDelegate.swift             # Menu bar 管理、狀態協調
│   ├── Models/
│   │   └── AppState.swift            # 狀態管理（idle/recording/processing）
│   ├── Views/
│   │   └── SettingsView.swift        # 設定介面（SwiftUI）
│   ├── Services/
│   │   ├── AudioRecorder.swift       # 音訊錄製
│   │   ├── WhisperService.swift      # Whisper API 整合
│   │   ├── OpenAIService.swift       # GPT-5-mini API 整合
│   │   ├── TextInputService.swift    # 剪貼簿與鍵盤模擬
│   │   └── HotkeyManager.swift       # 全域快捷鍵監聽
│   ├── Utilities/
│   │   └── KeychainHelper.swift      # API Key 加密儲存
│   └── Assets.xcassets/
│       └── AppIcon.appiconset/       # App Icon
└── lasay-icon.png                     # 原始 icon 設計
```

---

## 4. 使用說明

### 4.1 系統需求

- macOS 13.0 或以上
- 網路連線（API 調用）
- OpenAI API Key

### 4.2 權限設定

#### 麥克風權限
首次使用時系統會自動詢問，或手動前往：
- **系統設定** → **隱私權與安全性** → **麥克風**
- 勾選 **LaSay**

#### Accessibility 權限（全域快捷鍵）
- **系統設定** → **隱私權與安全性** → **輔助使用**
- 勾選 **LaSay**

### 4.3 設定步驟

1. 啟動 LaSay
2. 點擊 menu bar 的 LaSay 圖示
3. 選擇「設定...」
4. 輸入 **OpenAI API Key**
5. 選擇轉錄語言（繁體中文 / English）
6. （選填）啟用 AI 潤飾並自訂 System Prompt
7. 關閉設定視窗（會自動儲存）

### 4.4 使用方式

1. 在任何應用程式中將游標放在輸入框
2. 按住 **Fn + Space**
3. 開始說話
4. 放開 **Fn + Space**
5. 文字會自動出現在游標位置

---

## 5. API 成本

### 5.1 OpenAI Whisper
- **模型**：whisper-1
- **費用**：$0.006 / 分鐘
- **預估**：每次 5-10 秒語音約 $0.001 USD

### 5.2 OpenAI GPT-5-mini（如果啟用 AI 潤飾）
- **模型**：gpt-5-mini
- **費用**：$0.075 / 1M input tokens, $0.30 / 1M output tokens
- **預估**：每次約 100 tokens，約 $0.00004 USD

**總計**：每次使用約 $0.001-0.002 USD（啟用 AI 潤飾時）

---

## 6. 開發階段

### 已完成階段

- ✅ 階段 1：建立基礎 Xcode 專案
- ✅ 階段 2：完善 Menu Bar UI
- ✅ 階段 3：實作音訊錄製功能
- ✅ 階段 4：整合 Whisper API
- ✅ 階段 5：實作剪貼簿與自動貼上
- ✅ 階段 6：實作全域快捷鍵監聽（Fn + Space）
- ✅ 階段 7：整合 AI 文字潤飾（GPT-5-mini）
- ✅ App 更名為 LaSay 並更新 icon

### 未來可能的改進

- ⏳ 階段 8：設定持久化優化（部分完成）
- ⏳ 階段 9：錯誤處理與用戶體驗優化
- ⏳ 階段 10：打包、簽名與分發

---

## 7. 已知限制

- Terminal 中使用快捷鍵時可能無效（Terminal 特殊鍵盤處理）
- 需要網路連線（API 調用）
- 需要 OpenAI API Key（付費服務）
- 每次編譯後可能需要重新授予 Accessibility 權限

---

## 8. 版本資訊

- **當前版本**：1.0.0
- **App 名稱**：LaSay
- **Bundle ID**：com.tamio.VoiceScribe（內部識別符，保持不變以維持權限）
- **顯示名稱**：LaSay
