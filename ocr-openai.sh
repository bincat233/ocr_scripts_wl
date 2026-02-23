#!/usr/bin/env bash
set -euo pipefail

# deps: grim slurp wl-clipboard curl jq (websocat 可选: realtime 模式)
# paru -S --needed grim slurp wl-clipboard curl jq websocat
CONF_FILE="${OCR_CONFIG_FILE:-$HOME/.config/ocr_scripts_wl.conf}"
ENV_FILE="${OPENAI_ENV_FILE:-$HOME/.config/openai.env}"

# Load config files
set -a
if [ -f "$CONF_FILE" ]; then
  source "$CONF_FILE"
fi
if [ -f "$ENV_FILE" ]; then
  env_perm="$(stat -c '%a' "$ENV_FILE" 2>/dev/null || true)"
  if [ -n "$env_perm" ] && [ "$env_perm" != "600" ]; then
    printf 'warning: env file permission is %s, expected 600: %s\n' "$env_perm" "$ENV_FILE" >&2
  fi
  source "$ENV_FILE"
fi
set +a

: "${OPENAI_API_KEY:?OPENAI_API_KEY is required}"

# 视觉可用模型示例见官方文档示例:contentReference[oaicite:1]{index=1}
MODEL="${OPENAI_OCR_MODEL:-gpt-4o-mini}"
API_URL="${OPENAI_API_URL:-https://api.openai.com/v1/responses}"

# 输出控制
MAX_OUTPUT_TOKENS="${OPENAI_OCR_MAX_TOKENS:-1200}"
REALTIME_TIMEOUT_SEC="${OPENAI_OCR_REALTIME_TIMEOUT_SEC:-45}"
IMAGE_QUALITY="${OPENAI_OCR_IMAGE_QUALITY:-10}"

# Prompt：尽量“只输出识别文本”，不加解释
INSTRUCTIONS="${OPENAI_OCR_INSTRUCTIONS:-Extract all text from the image. Output only the extracted raw text. Preserve line breaks. Do not add any commentary.}"

build_responses_payload() {
  local model="$1"
  local instructions="$2"
  local image_data_url="$3"
  local max_tokens="$4"

  jq -n \
    --arg model "$model" \
    --arg instr "$instructions" \
    --arg img "$image_data_url" \
    --argjson max_tokens "$max_tokens" \
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
}

call_openai_responses_api() {
  local api_url="$1"
  local api_key="$2"
  local payload="$3"

  curl -sS "$api_url" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $api_key" \
    -d "$payload"
}

call_openai_realtime_api() {
  local model="$1"
  local api_key="$2"
  local instructions="$3"
  local image_data_url="$4"
  local max_tokens="$5"
  local timeout_sec="$6"
  local ws_url="wss://api.openai.com/v1/realtime?model=${model}"
  local beta_header="${OPENAI_OCR_REALTIME_BETA_HEADER:-OpenAI-Beta: realtime=v1}"
  local events_file out_file combined err_msg

  events_file="$(mktemp)"
  out_file="$(mktemp)"
  jq -n \
    --arg img "$image_data_url" \
    '{
      type: "conversation.item.create",
      item: {
        type: "message",
        role: "user",
        content: [
          { type: "input_text", text: "OCR this image." },
          { type: "input_image", image_url: $img }
        ]
      }
    }' >"$events_file"
  printf '\n' >>"$events_file"
  jq -n \
    --arg instr "$instructions" \
    --argjson max_tokens "$max_tokens" \
    '{
      type: "response.create",
      response: {
        modalities: ["text"],
        instructions: $instr,
        max_output_tokens: $max_tokens
      }
    }' >>"$events_file"
  printf '\n' >>"$events_file"

  if ! timeout "${timeout_sec}"s \
    websocat -q -t -E -B 8388608 \
    -H "Authorization: Bearer ${api_key}" \
    -H "${beta_header}" \
    "${ws_url}" <"$events_file" >"$out_file"; then
    rm -f "$events_file" "$out_file"
    printf 'OCR(OpenAI) realtime error: websocket request failed or timed out.\n' >&2
    return 1
  fi

  combined="$(
    jq -Rr '
      try (
        fromjson
        | if .type == "response.output_text.delta" then .delta // ""
          elif .type == "response.output_text.done" then .text // ""
          else ""
          end
      ) catch ""
    ' "$out_file" | tr -d '\000'
  )"
  rm -f "$events_file"
  if [[ -n "${combined//[[:space:]]/}" ]]; then
    rm -f "$out_file"
    printf '%s' "$combined"
    return 0
  fi

  err_msg="$(
    jq -Rr '
      try (
        fromjson
        | if .type == "error" then .error.message // .message // ""
          elif .type == "response.done" then (.response.status_details.error.message // "")
          else ""
          end
      ) catch ""
    ' "$out_file" | awk 'NF{print; exit}'
  )"
  rm -f "$out_file"
  [[ -n "$err_msg" ]] && printf '%s\n' "$err_msg" >&2
  return 1
}

extract_text_from_responses() {
  local response_json="$1"

  printf '%s' "$response_json" |
    jq -r '[.output[]?
            | select(.type=="message")
            | .content[]?
            | select(.type=="output_text")
            | .text]
           | join("")'
}

sanitize_ocr_text() {
  local raw_text="$1"

  printf '%s' "$raw_text" | sed -E '
    1s/^```[[:alnum:]_-]*[[:space:]]*$//
    $s/^[[:space:]]*```[[:space:]]*$//
  '
}

tmp_img="$(mktemp --suffix=.jpg)"
trap 'rm -f "$tmp_img"' EXIT

geom="$(slurp)"
grim -g "$geom" -t jpeg -q "$IMAGE_QUALITY" "$tmp_img"

b64="$(base64 -w0 <"$tmp_img")"
data_url="data:image/jpeg;base64,${b64}"

if [[ "$API_URL" == *"/v1/realtime"* ]] || [[ "$MODEL" == gpt-realtime* ]]; then
  if ! text="$(
    call_openai_realtime_api \
      "$MODEL" \
      "$OPENAI_API_KEY" \
      "$INSTRUCTIONS" \
      "$data_url" \
      "$MAX_OUTPUT_TOKENS" \
      "$REALTIME_TIMEOUT_SEC"
  )"; then
    notify-send -u critical -a "OCR(OpenAI)" "API error" "realtime request failed"
    printf 'OCR(OpenAI) API error: realtime request failed\n' >&2
    exit 1
  fi
else
  # 用 jq 生成 JSON，避免 shell 引号/转义问题（不需要 python）
  payload="$(build_responses_payload "$MODEL" "$INSTRUCTIONS" "$data_url" "$MAX_OUTPUT_TOKENS")"

  # 请求
  resp="$(call_openai_responses_api "$API_URL" "$OPENAI_API_KEY" "$payload")"

  # 提取文本：遍历 output -> message -> content -> output_text
  text="$(extract_text_from_responses "$resp")"
fi

text="$(sanitize_ocr_text "$text")"

# API 返回错误时，通常没有上面的结构；兜底把 error.message 打出来
if [[ -z "${text//[[:space:]]/}" ]]; then
  err="$(printf '%s' "${resp:-}" | jq -r '.error.message? // empty' 2>/dev/null || true)"
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
