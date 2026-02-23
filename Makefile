SHELL := /usr/bin/env bash
BINDIR ?= /usr/local/bin

.PHONY: help check-deps install uninstall

help:
	@echo "OCR scripts Make targets"
	@echo "  make check-deps       - Check required commands exist"
	@echo "  make install          - Install scripts to $(BINDIR)"
	@echo "  make uninstall        - Remove installed scripts from $(BINDIR)"
	@echo "  make install BINDIR=$$HOME/.local/bin   - User-local install"

check-deps:
	@missing=0; \
	for cmd in bash grim slurp wl-copy timeout tesseract curl jq stat base64 mktemp head sed; do \
		if ! command -v $$cmd >/dev/null 2>&1; then \
			echo "missing dependency: $$cmd"; \
			missing=1; \
		fi; \
	done; \
	if ! command -v websocat >/dev/null 2>&1; then \
		echo "warning: optional dependency missing: websocat (required for realtime mode)"; \
	fi; \
	if ! command -v notify-send >/dev/null 2>&1; then \
		echo "warning: optional dependency missing: notify-send (desktop notifications disabled)"; \
	fi; \
	if [ $$missing -ne 0 ]; then \
		echo "dependency check failed"; \
		exit 1; \
	fi; \
	echo "dependencies: OK"

install: check-deps
	@mkdir -p "$(BINDIR)"
	@install -m 755 ocr.sh "$(BINDIR)/ocr.sh"
	@install -m 755 ocr-openai.sh "$(BINDIR)/ocr-openai.sh"
	@install -m 755 ocr-tesseract.sh "$(BINDIR)/ocr-tesseract.sh"
	@echo "installed to $(BINDIR)"

uninstall:
	@rm -f "$(BINDIR)/ocr" "$(BINDIR)/ocr-openai.sh" "$(BINDIR)/ocr-tesseract.sh"
	@echo "removed from $(BINDIR)"
