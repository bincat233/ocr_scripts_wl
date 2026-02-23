# OCR Scripts (Wayland)

Screenshot OCR for Wayland:

- Online: use OpenAI API
- Offline: automatically fall back to tesseract

## Install

1. Install dependencies (examples):

```bash
# Arch
sudo pacman -S --needed grim slurp wl-clipboard libnotify coreutils curl jq tesseract tesseract-data-eng tesseract-data-chi_sim

# Ubuntu
sudo apt update
sudo apt install -y grim slurp wl-clipboard libnotify-bin coreutils curl jq tesseract-ocr tesseract-ocr-eng tesseract-ocr-chi-sim
```

1. Check dependencies:

```bash
make check-deps
```

1. Install scripts (default: `/usr/local/bin`):

```bash
make install
```

Install without sudo:

```bash
make install BINDIR="$HOME/.local/bin"
```

## Usage

Run:

```bash
ocr.sh
```

Flow: select area -> OCR runs -> result is copied to clipboard.

## Minimal OpenAI Setup

```bash
mkdir -p ~/.config
cat > ~/.config/openai.env <<'ENV'
OPENAI_API_KEY=sk-xxxxx
ENV
chmod 600 ~/.config/openai.env
```

## Realtime Mode (`gpt-realtime-mini`)

Install extra dependency `websocat`:

```bash
# Arch
sudo pacman -S --needed websocat

# Ubuntu
sudo apt install -y websocat
```

Add to `~/.config/openai.env`:

```bash
OPENAI_OCR_MODEL=gpt-realtime-mini
OPENAI_API_URL=https://api.openai.com/v1/realtime
```

Notes:
- The script sends OCR requests via Realtime WebSocket.
- If realtime fails, it auto-falls back to `responses` (default `gpt-4o-mini`).
