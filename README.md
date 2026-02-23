# OCR Scripts (Wayland)

Wayland screenshot OCR:

- Online: use OpenAI
- Offline: automatically fall back to tesseract

## Installation & Setup

**Check dependencies:**

```bash
make check-deps
```

**Install dependencies** (examples; use your distro's package manager):

```bash
# Arch
sudo pacman -S --needed grim slurp wl-clipboard libnotify coreutils curl jq tesseract tesseract-data-eng tesseract-data-chi_sim

# Ubuntu
sudo apt update
sudo apt install -y grim slurp wl-clipboard libnotify-bin coreutils curl jq tesseract-ocr tesseract-ocr-eng tesseract-ocr-chi-sim
```

**Install scripts** (default: `/usr/local/bin`):

```bash
make install
```

Install without sudo:

```bash
make install BINDIR="$HOME/.local/bin"
```

**Copy config and set your OpenAI key**:

```bash
MY_OPENAI_KEY=sk-xxxxxx
mkdir -p ~/.config
cp ocr_scripts_wl.conf ~/.config/ocr_scripts_wl.conf
sed -i "s/^\(OPENAI_API_KEY=\).*/\1$MY_OPENAI_KEY/" ~/.config/ocr_scripts_wl.conf
```

## Usage

Run:

```bash
ocr.sh
```

Or bind the script to a desktop shortcut key.

GNOME: `Settings -> Keyboard -> View and Customize Shortcuts -> Custom Shortcuts`, add command `ocr.sh` and bind a key.

sway: add `bindsym $mod+Shift+o exec --no-startup-id ocr.sh` to `~/.config/sway/config`, then run `swaymsg reload`.

Flow: select area -> OCR runs -> result is copied to clipboard.

## Configuration

Config file: `~/.config/ocr_scripts_wl.conf`

```bash
MY_OPENAI_KEY=sk-xxxxxx
mkdir -p ~/.config
cp ocr_scripts_wl.conf ~/.config/ocr_scripts_wl.conf
chmod 600 ~/.config/ocr_scripts_wl.conf
sed -i "s/^\(OPENAI_API_KEY=\).*/\1$MY_OPENAI_KEY/" ~/.config/ocr_scripts_wl.conf
```

Also, the script reads `OPENAI_API_KEY` from `~/.config/openai.env`.

Parameter reference:

- `OPENAI_API_KEY`: OpenAI API key.
- `OPENAI_API_URL`: API endpoint. You can use `https://api.openai.com/v1/realtime` or `https://api.openai.com/v1/responses`.
- `OPENAI_OCR_MODEL`: Model name, for example `gpt-realtime-mini`, `gpt-realtime`, `gpt-4o-mini`.
- `OPENAI_OCR_MAX_TOKENS`: Max output tokens.
- `OPENAI_OCR_REALTIME_TIMEOUT_SEC`: Realtime timeout in seconds.
- `OPENAI_OCR_IMAGE_QUALITY`: Screenshot JPEG quality (`grim -q`). Higher means clearer and larger.
- `OPENAI_OCR_INSTRUCTIONS`: OCR prompt.

Notes:

- Realtime API is faster. Install `websocat`, set `OPENAI_API_URL` to `https://api.openai.com/v1/realtime`, and set `OPENAI_OCR_MODEL` to `gpt-realtime-mini` or `gpt-realtime`.
- Script defaults are used when a value is not set.
- The script reads `~/.config/ocr_scripts_wl.conf` first, then `~/.config/openai.env`.
