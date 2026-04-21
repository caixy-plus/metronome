#!/bin/bash
#==============================================================================
# Metronome Release Script
# Usage: ./scripts/release.sh <version>
# Example: ./scripts/release.sh 1.3.5
#          ./scripts/release.sh 1.3.5+1
#==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PUBSPEC="$PROJECT_DIR/pubspec.yaml"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查参数
if [ -z "$1" ]; then
    error "用法: $0 <version>"
    error "示例: $0 1.3.5"
    exit 1
fi

NEW_VERSION="$1"

# 校验版本格式 (x.y.z 或 x.y.z+build)
if ! echo "$NEW_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(\+[0-9]+)?$'; then
    error "版本号格式无效: $NEW_VERSION"
    error "期望格式: x.y.z 或 x.y.z+build (例如: 1.3.5 或 1.3.5+1)"
    exit 1
fi

cd "$PROJECT_DIR"

# 检查 git 状态
if ! git diff --quiet && ! git diff --cached --quiet; then
    error "存在未提交的更改，请先 commit 或 stash"
    git status --short
    exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
    warn "存在未跟踪的文件，可能被遗漏:"
    git status --porcelain
fi

# 读取当前版本
CURRENT_VERSION=$(grep '^version:' "$PUBSPEC" | sed 's/version: *//' | tr -d ' ')
info "当前版本: $CURRENT_VERSION"
info "新版本:   $NEW_VERSION"

# 确认
echo ""
read -p "确认发布 $NEW_VERSION? [y/N] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "已取消"
    exit 0
fi

# 1. 更新 pubspec.yaml
info "更新 pubspec.yaml 版本号..."
sed -i '' "s/^version:.*/version: $NEW_VERSION/" "$PUBSPEC"

# 2. 验证更新
VERIFY=$(grep '^version:' "$PUBSPEC" | sed 's/version: *//' | tr -d ' ')
if [ "$VERIFY" != "$NEW_VERSION" ]; then
    error "版本号更新失败，期望 $NEW_VERSION，实际 $VERIFY"
    exit 1
fi
info "版本号更新成功: $NEW_VERSION"

# 3. Git commit
info "提交版本号更新..."
git add "$PUBSPEC"
git commit -m "chore: bump version to $NEW_VERSION

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"

# 4. Git push
info "推送到远程..."
git push

# 5. 创建 tag
info "创建 tag v$NEW_VERSION..."
git tag "v$NEW_VERSION" -m "Release v$NEW_VERSION

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"

# 6. 推送 tag
info "推送 tag 到远程..."
git push origin "v$NEW_VERSION"

echo ""
info "发布完成! v$NEW_VERSION"
info "GitHub Actions 构建已触发"
