# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 專案概述

LaSay 是一款 macOS 原生的系統級語音輸入工具，使用者可透過全域快捷鍵 **Fn + Space** 在任何應用中觸發語音輸入，語音會透過 OpenAI Whisper API 轉錄為文字，並可選擇性使用 GPT-5-mini 進行 AI 潤飾，最後自動貼到當前游標位置。

核心差異化功能：內建 AI 文字潤飾，可自動優化口語表達、移除贅字、修正文法。

## 開發命令

### 構建與運行
```bash
# 在 Xcode 中開啟專案
open VoiceScribe/VoiceScribe.xcodeproj

# 或使用 xcodebuild（從 VoiceScribe/VoiceScribe/ 目錄）
cd VoiceScribe/VoiceScribe
xcodebuild -scheme VoiceScribe -configuration Release
```

### 測試運行
在 Xcode 中使用 **Cmd + R** 運行應用，或選擇 **Product > Run**。

### 清理構建產物
```bash
cd VoiceScribe/VoiceScribe
rm -rf build/
```

## 架構設計

### 應用類型與入口
- **Menu Bar App**：使用 AppDelegate 管理，無主視窗
- 入口點：`VoiceScribeApp.swift` (SwiftUI @main) + `AppDelegate.swift` (NSApplicationDelegate)
- UI 框架：SwiftUI (SettingsView) + AppKit (Menu Bar)

### 狀態管理
- `AppState.swift`：單例模式管理應用狀態 (`idle` / `recording` / `processing`)
- 使用 Combine 框架進行狀態變化通知
- Menu bar icon 會根據狀態改變顏色和動畫：
  - 待機：灰色麥克風
  - 錄音中：紅色麥克風（閃爍動畫）
  - 處理中：藍色波形（旋轉動畫）

### 核心服務層 (`Services/`)

1. **HotkeyManager.swift** - 全域快捷鍵監聽
   - 使用 CGEvent Event Tap 監聽 Fn + Space
   - 需要 **Accessibility 權限**
   - 實作按下/放開的獨立回調
   - 注意：每次編譯後可能需要重新授予權限

2. **AudioRecorder.swift** - 音訊錄製
   - 使用 AVFoundation (AVAudioRecorder)
   - 錄製格式：M4A
   - 需要**麥克風權限**
   - 提供錄製完成和錯誤回調

3. **WhisperService.swift** - 語音轉錄
   - 整合 OpenAI Whisper API
   - 支援語言參數（繁體中文 / 英文）
   - 從 UserDefaults 讀取語言設定 (`transcription_language`)

4. **OpenAIService.swift** - AI 文字潤飾
   - 整合 GPT-5-mini API
   - 可選功能（透過 `enable_ai_polish` UserDefaults 開關）
   - 支援自訂 System Prompt (`custom_system_prompt`)

5. **TextInputService.swift** - 剪貼簿與自動貼上
   - 透過複製+模擬 Cmd+V 實現自動貼上
   - 可選擇是否還原原剪貼簿內容 (`restore_clipboard`)

### 工具層 (`Utilities/`)

1. **KeychainHelper.swift** - API Key 安全儲存
   - 使用 macOS Keychain 加密儲存 OpenAI API Key
   - 服務名稱：`com.tamio.LaSay.openai_api_key`

2. **LocalizationHelper.swift** - 多語言支援
   - 支援繁體中文和英文
   - Menu bar 固定使用英文，設定視窗和警告框根據語言設定顯示

### 設定持久化
使用 `UserDefaults` 儲存以下設定：
- `openai_api_key_set`：是否已設定 API Key (boolean)
- `transcription_language`：轉錄語言 ("zh" / "en")
- `enable_ai_polish`：是否啟用 AI 潤飾 (boolean)
- `custom_system_prompt`：自訂 System Prompt (string, optional)
- `auto_paste`：是否自動貼上 (boolean)
- `restore_clipboard`：是否還原剪貼簿 (boolean)
- `has_launched_before`：是否首次啟動 (boolean)
- `interface_language`：介面語言 ("zh" / "en")

實際的 OpenAI API Key 儲存在 **Keychain**，不使用 UserDefaults。

## 權限要求

### 1. 麥克風權限
- 首次錄音時自動請求
- 手動路徑：**系統設定 → 隱私權與安全性 → 麥克風 → 勾選 LaSay**

### 2. Accessibility 權限（全域快捷鍵）
- 使用 `AXIsProcessTrustedWithOptions` 請求
- 手動路徑：**系統設定 → 隱私權與安全性 → 輔助使用 → 勾選 LaSay**
- **重要**：每次重新編譯後可能需要重新授予權限

### 3. 通知權限（選填）
- 用於錯誤提示和操作完成通知

## 工作流程

1. 使用者按住 **Fn + Space**
2. `HotkeyManager` 觸發 `onHotkeyPressed`
3. `AppDelegate.startRecording()` → 狀態變為 `recording`
4. `AudioRecorder` 開始錄音
5. 使用者放開 **Fn + Space**
6. `HotkeyManager` 觸發 `onHotkeyReleased`
7. `AppDelegate.stopRecording()` → 狀態變為 `processing`
8. `WhisperService` 調用 API 轉錄語音
9. （可選）`OpenAIService` 進行 AI 潤飾
10. `TextInputService` 自動貼上文字
11. 狀態回到 `idle`，並重新啟動 hotkey 監聽

## 已知限制與注意事項

- **Terminal 限制**：Terminal 有特殊鍵盤處理，快捷鍵可能無效
- **權限重置**：每次編譯後可能需要重新授予 Accessibility 權限
- **API 依賴**：需要網路連線和有效的 OpenAI API Key
- **Bundle ID**：`com.tamio.LaSay`

## API 成本參考
- **Whisper**：約 $0.001 USD / 次（5-10 秒語音）
- **GPT-5-mini**：約 $0.00004 USD / 次（100 tokens）
- **總計**：約 $0.001-0.002 USD / 次

## 開發注意事項

- 所有 UI 更新必須在主線程執行（使用 `DispatchQueue.main.async`）
- 狀態變化透過 `AppState.shared` 統一管理
- Menu bar 選單文字固定使用英文，設定視窗根據語言設定顯示
- 錄音完成後需要刪除暫存音檔（`audioRecorder.deleteRecording(at:)`）
- 自動貼上後需延遲重啟 hotkey 監聽（防止事件干擾）
- 首次啟動時會自動開啟設定視窗引導使用者
