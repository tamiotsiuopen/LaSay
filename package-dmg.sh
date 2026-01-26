#!/bin/bash

# LaSay DMG 打包腳本
# 用法: ./package-dmg.sh [版本後綴]
# 範例: ./package-dmg.sh beta
#       ./package-dmg.sh alpha
#       ./package-dmg.sh        (不加後綴)

set -e  # 遇到錯誤立即停止

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 專案路徑
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_PATH="${PROJECT_ROOT}/VoiceScribe/build/Build/Products/Release/LaSay.app"
ICON_PATH="${PROJECT_ROOT}/lasay-icon.png"

# 檢查 app 是否存在
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}錯誤: 找不到 LaSay.app${NC}"
    echo "請先用 Xcode 建置專案"
    echo "預期位置: $APP_PATH"
    exit 1
fi

# 從 Info.plist 讀取版本號
VERSION=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleShortVersionString)
BUILD=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleVersion)

echo -e "${GREEN}找到 LaSay.app${NC}"
echo "版本: $VERSION (Build $BUILD)"

# 處理版本後綴
VERSION_SUFFIX=""
if [ -n "$1" ]; then
    VERSION_SUFFIX="-$1"
    echo "版本後綴: $1"
fi

# 生成 DMG 檔名
DMG_NAME="LaSay-v${VERSION}${VERSION_SUFFIX}.dmg"
DMG_PATH="${PROJECT_ROOT}/${DMG_NAME}"

# 如果 DMG 已存在，先刪除
if [ -f "$DMG_PATH" ]; then
    echo -e "${YELLOW}移除舊的 DMG: ${DMG_NAME}${NC}"
    rm "$DMG_PATH"
fi

echo -e "${GREEN}開始創建 DMG...${NC}"

# 創建 DMG
create-dmg \
  --volname "LaSay" \
  --volicon "$ICON_PATH" \
  --window-pos 200 120 \
  --window-size 660 400 \
  --icon-size 160 \
  --icon "LaSay.app" 180 170 \
  --hide-extension "LaSay.app" \
  --app-drop-link 480 170 \
  --no-internet-enable \
  "$DMG_PATH" \
  "$APP_PATH"

# 檢查結果
if [ -f "$DMG_PATH" ]; then
    FILE_SIZE=$(du -h "$DMG_PATH" | cut -f1)
    echo ""
    echo -e "${GREEN}✓ DMG 創建成功！${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "檔案名稱: ${DMG_NAME}"
    echo "檔案大小: ${FILE_SIZE}"
    echo "儲存位置: ${DMG_PATH}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "你現在可以分發這個 DMG 給測試使用者了！"
else
    echo -e "${RED}✗ DMG 創建失敗${NC}"
    exit 1
fi
