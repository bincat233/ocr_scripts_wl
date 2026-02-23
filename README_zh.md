# OCR Scripts (Wayland)

截图 OCR：在线走 OpenAI，离线自动回退 tesseract。

## 安装

1. 安装依赖（示例，按发行版替换包管理器）：

```bash
# Arch
sudo pacman -S --needed grim slurp wl-clipboard libnotify coreutils curl jq tesseract tesseract-data-eng tesseract-data-chi_sim

# Ubuntu
sudo apt update
sudo apt install -y grim slurp wl-clipboard libnotify-bin coreutils curl jq tesseract-ocr tesseract-ocr-eng tesseract-ocr-chi-sim
```

1. 检查依赖：

```bash
make check-deps
```

1. 安装脚本（默认 `/usr/local/bin`）：

```bash
make install
```

不想用 sudo：

```bash
make install BINDIR="$HOME/.local/bin"
```

## 使用

直接运行：

```bash
ocr.sh
```

操作流程：框选区域 -> 自动 OCR -> 结果复制到剪贴板。

## OpenAI 最小配置

```bash
mkdir -p ~/.config
cat > ~/.config/openai.env <<'ENV'
OPENAI_API_KEY=sk-xxxxx
ENV
chmod 600 ~/.config/openai.env
```

## Realtime 模式（gpt-realtime-mini）

需要额外安装 `websocat`：

```bash
# Arch
sudo pacman -S --needed websocat

# Ubuntu
sudo apt install -y websocat
```

在 `~/.config/openai.env` 里加上：

```bash
OPENAI_OCR_MODEL=gpt-realtime-mini
OPENAI_API_URL=https://api.openai.com/v1/realtime
OPENAI_OCR_IMAGE_QUALITY=70
```

说明：
- 脚本会通过 Realtime WebSocket 发送 OCR 请求。
- 如果 realtime 失败，会自动回退到 `responses`（默认 `gpt-4o-mini`）。
