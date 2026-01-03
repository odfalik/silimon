# Silimon Makefile

PREFIX ?= /usr/local
BINARY = silimon
BUILD_DIR = .build/release

.PHONY: all build release install uninstall clean setup-sudo run

all: build

build:
	swift build

release:
	swift build -c release

install: release
	install -d $(PREFIX)/bin
	install $(BUILD_DIR)/$(BINARY) $(PREFIX)/bin/$(BINARY)
	@echo ""
	@echo "Installed to $(PREFIX)/bin/$(BINARY)"
	@echo ""
	@echo "Run 'sudo Scripts/setup-sudo.sh' to enable passwordless powermetrics"

uninstall:
	rm -f $(PREFIX)/bin/$(BINARY)
	@echo "Uninstalled $(BINARY)"
	@echo "Run 'sudo Scripts/uninstall.sh' to remove sudoers entry"

clean:
	swift package clean
	rm -rf .build

setup-sudo:
	sudo Scripts/setup-sudo.sh

run: build
	.build/debug/$(BINARY)

# Development helpers
dev: build
	@echo "Starting silimon in development mode..."
	@echo "Note: Run with 'sudo make dev' for full metrics access"
	.build/debug/$(BINARY)

# Show help
help:
	@echo "Silimon - Apple Silicon Performance Monitor"
	@echo ""
	@echo "Usage:"
	@echo "  make build       - Build debug version"
	@echo "  make release     - Build release version"
	@echo "  make install     - Install to $(PREFIX)/bin"
	@echo "  make uninstall   - Remove from $(PREFIX)/bin"
	@echo "  make clean       - Clean build artifacts"
	@echo "  make setup-sudo  - Setup passwordless powermetrics"
	@echo "  make run         - Build and run"
	@echo "  make dev         - Build and run in dev mode"
