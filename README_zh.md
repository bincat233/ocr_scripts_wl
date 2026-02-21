# OCR Scripts (Wayland)

截图 OCR：在线走 OpenAI，离线自动回退 tesseract。

## 安装

1) 安装依赖（示例，按发行版替换包管理器）：

```bash
# Arch
sudo pacman -S --needed grim slurp wl-clipboard libnotify coreutils curl jq tesseract tesseract-data-eng tesseract-data-chi_sim

# Ubuntu
sudo apt update
sudo apt install -y grim slurp wl-clipboard libnotify-bin coreutils curl jq tesseract-ocr tesseract-ocr-eng tesseract-ocr-chi-sim
```

2) 检查依赖：

```bash
make check-deps
```

3) 安装脚本（默认 `/usr/local/bin`）：

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
ocr
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
