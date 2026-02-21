#!/usr/bin/env bash
set -euo pipefail

# deps: grim slurp wl-clipboard curl jq (perl 可选，用于中文空格清理)
# paru -S --needed grim slurp wl-clipboard curl jq perl
ENV_FILE="${OPENAI_ENV_FILE:-$HOME/.config/openai.env}"

# Try to export API Key
set -a
if [ -f "$ENV_FILE" ]; then
  env_perm="$(stat -c '%a' "$ENV_FILE" 2>/dev/null || true)"
  if [ -n "$env_perm" ] && [ "$env_perm" != "600" ]; then
    printf 'warning: env file permission is %s, expected 600: %s\n' "$env_perm" "$ENV_FILE" >&2
  fi
  source "$ENV_FILE"
fi
set +a

: "${OPENAI_API_KEY:?OPENAI_API_KEY is required}"

#MODEL="${OPENAI_OCR_MODEL:-gpt-5-mini}" # 视觉可用模型示例见官方文档示例:contentReference[oaicite:1]{index=1}
MODEL="${OPENAI_OCR_MODEL:-gpt-4.1-mini}" # 视觉可用模型示例见官方文档示例:contentReference[oaicite:1]{index=1}
API_URL="${OPENAI_API_URL:-https://api.openai.com/v1/responses}"

# 输出控制
MAX_OUTPUT_TOKENS="${OPENAI_OCR_MAX_TOKENS:-1200}"

# Prompt：尽量“只输出识别文本”，不加解释
INSTRUCTIONS="${OPENAI_OCR_INSTRUCTIONS:-Extract all text from the image. Output only the extracted text. Preserve line breaks. Do not add any commentary.}"

tmp_img="$(mktemp --suffix=.png)"
trap 'rm -f "$tmp_img"' EXIT

geom="$(slurp)"
grim -g "$geom" -t jpeg -q 2 "$tmp_img"

b64="$(base64 -w0 <"$tmp_img")"
data_url="data:image/png;base64,${b64}"

# 用 jq 生成 JSON，避免 shell 引号/转义问题（不需要 python）
payload="$(
  jq -n \
    --arg model "$MODEL" \
    --arg instr "$INSTRUCTIONS" \
    --arg img "$data_url" \
    --argjson max_tokens "$MAX_OUTPUT_TOKENS" \
    '{
      model: $model,
      instructions: $instr,
      max_output_tokens: $max_tokens,
      input: [{
        role: "user",
        content: [
          { type: "input_text", text: "OCR this image." },
          { type: "input_image", image_url: $img }
        ]
      }]
    }'
)"

# 请求
resp="$(
  curl -sS "$API_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d "$payload"
)"

# 提取文本：遍历 output -> message -> content -> output_text
text="$(
  printf '%s' "$resp" |
    jq -r '[.output[]? 
            | select(.type=="message") 
            | .content[]? 
            | select(.type=="output_text") 
            | .text] 
           | join("")'
)"

# API 返回错误时，通常没有上面的结构；兜底把 error.message 打出来
if [[ -z "${text//[[:space:]]/}" ]]; then
  err="$(printf '%s' "$resp" | jq -r '.error.message? // empty')"
  if [[ -n "$err" ]]; then
    notify-send -u critical -a "OCR(OpenAI)" "API error" "$err"
    printf 'OCR(OpenAI) API error: %s\n' "$err" >&2
    exit 1
  fi
  notify-send -u low -a "OCR(OpenAI)" "No text detected"
  exit 0
fi

# 复制到剪贴板
printf '%s' "$text" | wl-copy

preview="$(printf '%s' "$text" | head -c 200)"
notify-send -u low -a "OCR(OpenAI)" "Copied to clipboard" "$preview"
