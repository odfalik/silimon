# Silimon Makefile

PREFIX ?= /usr/local
BINARY = silimon
BUILD_DIR = .build/release

.PHONY: all build release install uninstall clean run stop

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
	@echo "  make build       - Build debug version"
	@echo "  make release     - Build release version"
	@echo "  make install     - Install to $(PREFIX)/bin"
	@echo "  make uninstall   - Remove from $(PREFIX)/bin"
	@echo "  make clean       - Clean build artifacts"
	@echo "  make run         - Build and run"
	@echo "  make dev         - Build and run in dev mode"
	@echo "  make stop        - Stop running silimon"
