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
