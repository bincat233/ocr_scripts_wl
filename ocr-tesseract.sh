#!/usr/bin/env bash
set -euo pipefail

# 语言：英文+简体中文（按需改）
LANGS="${OCR_LANGS:-eng+chi_sim}"

# 选区截图（PNG 流） -> tesseract 从 stdin 读 -> stdout 输出文本
# --psm 6：假设为一块文本区域；你也可以试 3/4/7 等
text="$(
  grim -g "$(slurp)" -t png - |
    tesseract stdin stdout -l "$LANGS" --psm "${OCR_PSM:-6}" 2>/dev/null |
    sed -E ':a; s/([一-龥])[ \t]+([一-龥])/\1\2/g; ta; s/[[:space:]]\+$//' # 清理中文间空格 + 去行尾空白
)"

# 空结果直接退出（避免把空覆盖剪贴板）
if [[ -z "${text//[[:space:]]/}" ]]; then
  notify-send -u low -a "OCR" "No text detected"
  exit 0
fi

# 复制到剪贴板
printf '%s' "$text" | wl-copy

# 通知（可选：只显示前 N 字，避免刷屏）
preview="$(printf '%s' "$text" | head -c 200)"
notify-send -u low -a "OCR" "Copied to clipboard" "$preview"
