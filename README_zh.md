# OCR Scripts (Wayland)

Wayland 截图 OCR：

- 在线：使用 OpenAI
- 离线：自动回退到 tesseract

## 安装配置

**检查依赖:**

```bash
make check-deps
```

**安装依赖**（示例，按发行版替换包管理器）:

```bash
# Arch
sudo pacman -S --needed grim slurp wl-clipboard libnotify coreutils curl jq tesseract tesseract-data-eng tesseract-data-chi_sim

# Ubuntu
sudo apt update
sudo apt install -y grim slurp wl-clipboard libnotify-bin coreutils curl jq tesseract-ocr tesseract-ocr-eng tesseract-ocr-chi-sim
```

**安装脚本**（默认 `/usr/local/bin`）:

```bash
make install
```

不想用 sudo：

```bash
make install BINDIR="$HOME/.local/bin"
```

**复制配置文件并设置自己的 OpenAI Key**:

```bash
MY_OPENAI_KEY=sk-xxxxxx
mkdir -p ~/.config
cp ocr_scripts_wl.conf ~/.config/ocr_scripts_wl.conf
sed -i "s/^\(OPENAI_API_KEY=\).*/\1$MY_OPENAI_KEY/" ~/.config/ocr_scripts_wl.conf
```

## 使用

直接运行：

```bash
ocr.sh
```

或将脚本绑定至桌面环境的快捷键

Gnome：`设置 -> 键盘 -> 查看及自定义快捷键 -> 自定义快捷键`，添加命令 `ocr.sh` 并绑定按键。

sway：在 `~/.config/sway/config` 添加 `bindsym $mod+Shift+o exec --no-startup-id ocr.sh`，然后执行 `swaymsg reload`。

流程：框选区域 -> 自动 OCR -> 结果复制到剪贴板。

## 配置

配置文件：`~/.config/ocr_scripts_wl.conf`

此外, 脚本也会从 `~/.config/openai.env` 读取 `OPENAI_API_KEY`。

参数说明：

- `OPENAI_API_KEY`：OpenAI API Key。
- `OPENAI_API_URL`：接口地址。可用 `https://api.openai.com/v1/realtime` 或 `https://api.openai.com/v1/responses`。
- `OPENAI_OCR_MODEL`：模型名，例如 `gpt-realtime-mini`、`gpt-realtime`、`gpt-4o-mini`。
- `OPENAI_OCR_MAX_TOKENS`：最大输出 token 数。
- `OPENAI_OCR_REALTIME_TIMEOUT_SEC`：Realtime 请求超时秒数。
- `OPENAI_OCR_IMAGE_QUALITY`：截图 JPEG 质量（`grim -q`），越高越清晰，体积也越大。
- `OPENAI_OCR_INSTRUCTIONS`：OCR 提示词。

补充：

- 使用 Realtime API 更快，需安装 `websocat`
  - 并把 `OPENAI_API_URL` 设为 `https://api.openai.com/v1/realtime`
  - 模型设为 `OPENAI_OCR_MODEL=gpt-realtime-mini` 或 `OPENAI_OCR_MODEL=gpt-realtime`。
- 未配置时使用脚本内默认值。
- 脚本会先读取 `~/.config/ocr_scripts_wl.conf`，再读取 `~/.config/openai.env`。
