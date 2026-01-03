# Silimon Makefile

PREFIX ?= /usr/local
BINARY = silimon
BUILD_DIR = .build/release

# Minimum requirements
MIN_MACOS = 13
REQUIRED_ARCH = arm64

.PHONY: all build release install uninstall clean run stop check-compat

all: build

# Check system compatibility before building
check-compat:
	@echo "Checking system compatibility..."
	@ARCH=$$(uname -m); \
	if [ "$$ARCH" != "$(REQUIRED_ARCH)" ]; then \
		echo ""; \
		echo "ERROR: Silimon requires Apple Silicon (arm64)."; \
		echo "       Your system is $$ARCH."; \
		echo "       Silimon does not support Intel Macs."; \
		echo ""; \
		exit 1; \
	fi
	@MACOS_MAJOR=$$(sw_vers -productVersion | cut -d. -f1); \
	if [ "$$MACOS_MAJOR" -lt $(MIN_MACOS) ]; then \
		echo ""; \
		echo "ERROR: Silimon requires macOS 13.0 (Ventura) or later."; \
		echo "       Your system is macOS $$(sw_vers -productVersion)."; \
		echo ""; \
		exit 1; \
	fi
	@if ! command -v swift >/dev/null 2>&1; then \
		echo ""; \
		echo "ERROR: Swift compiler not found."; \
		echo "       Please install Xcode or Xcode Command Line Tools."; \
		echo ""; \
		exit 1; \
	fi
	@echo "Compatibility check passed!"

build: check-compat
	swift build

release: check-compat
	swift build -c release

install: release
	install -d $(PREFIX)/bin
	install $(BUILD_DIR)/$(BINARY) $(PREFIX)/bin/$(BINARY)
	@echo ""
	@echo "Installed to $(PREFIX)/bin/$(BINARY)"
	@echo "Run 'silimon' to start!"

uninstall:
	rm -f $(PREFIX)/bin/$(BINARY)
	@echo "Uninstalled $(BINARY)"

clean:
	swift package clean
	rm -rf .build

run: build
	.build/debug/$(BINARY)

# Development helpers
dev: build
	@echo "Starting silimon in development mode..."
	@echo "Use 'make stop' to stop silimon"
	.build/debug/$(BINARY)

stop:
	@pkill -f "$(BINARY)" 2>/dev/null && echo "Stopped silimon" || echo "silimon is not running"

# Show help
help:
	@echo "Silimon - Apple Silicon Performance Monitor"
	@echo ""
	@echo "Usage:"
	@echo "  make check-compat - Check system compatibility"
	@echo "  make build        - Build debug version"
	@echo "  make release      - Build release version"
	@echo "  make install      - Install to $(PREFIX)/bin"
	@echo "  make uninstall    - Remove from $(PREFIX)/bin"
	@echo "  make clean        - Clean build artifacts"
	@echo "  make run          - Build and run"
	@echo "  make dev          - Build and run in dev mode"
	@echo "  make stop         - Stop running silimon"
