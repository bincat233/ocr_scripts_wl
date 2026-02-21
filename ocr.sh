#!/usr/bin/env bash
#set -euo pipefail

# 可调：连通性探测目标/超时
PROBE_HOST="${OCR_NET_PROBE_HOST:-1.1.1.1}"
PROBE_PORT="${OCR_NET_PROBE_PORT:-443}"
PROBE_TIMEOUT="${OCR_NET_PROBE_TIMEOUT:-0.8}"

# 可调：脚本路径
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OPENAI_SCRIPT="${OCR_OPENAI_SCRIPT:-$SCRIPT_DIR/ocr-openai.sh}"
TESS_SCRIPT="${OCR_TESS_SCRIPT:-$SCRIPT_DIR/ocr-tesseract.sh}"

have_net() {
  # bash 内建 /dev/tcp：无需额外依赖
  timeout "${PROBE_TIMEOUT}" bash -c ">/dev/tcp/${PROBE_HOST}/${PROBE_PORT}" 2>/dev/null
}

if have_net; then
  exec "$OPENAI_SCRIPT"
else
  exec "$TESS_SCRIPT"
fi
