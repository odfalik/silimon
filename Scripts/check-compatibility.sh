#!/bin/bash
# Silimon Compatibility Check Script
# Run this before installing to verify your system meets requirements

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Silimon Compatibility Check"
echo "==========================="
echo ""

ERRORS=0
WARNINGS=0

# Check architecture
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    echo -e "${GREEN}[PASS]${NC} Architecture: Apple Silicon (arm64)"
else
    echo -e "${RED}[FAIL]${NC} Architecture: $ARCH"
    echo "       Silimon only supports Apple Silicon Macs (M1, M2, M3, M4)"
    ERRORS=$((ERRORS + 1))
fi

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion)
MAJOR=$(echo "$MACOS_VERSION" | cut -d. -f1)
if [ "$MAJOR" -ge 13 ]; then
    echo -e "${GREEN}[PASS]${NC} macOS Version: $MACOS_VERSION"
else
    echo -e "${RED}[FAIL]${NC} macOS Version: $MACOS_VERSION (requires 13.0+)"
    echo "       Please upgrade to macOS Ventura or later"
    ERRORS=$((ERRORS + 1))
fi

# Check for Xcode/Swift
if command -v swift &> /dev/null; then
    echo -e "${GREEN}[PASS]${NC} Swift: Available"
else
    echo -e "${RED}[FAIL]${NC} Swift: Not found"
    echo "       Install Xcode or Xcode Command Line Tools"
    ERRORS=$((ERRORS + 1))
fi

# Check for vm_stat
if [ -x /usr/bin/vm_stat ]; then
    echo -e "${GREEN}[PASS]${NC} vm_stat: Available"
else
    echo -e "${YELLOW}[WARN]${NC} vm_stat: Not found at /usr/bin/vm_stat"
    echo "       Memory metrics may not work"
    WARNINGS=$((WARNINGS + 1))
fi

# Check for memory_pressure
if [ -x /usr/bin/memory_pressure ]; then
    echo -e "${GREEN}[PASS]${NC} memory_pressure: Available"
else
    echo -e "${YELLOW}[WARN]${NC} memory_pressure: Not found"
    WARNINGS=$((WARNINGS + 1))
fi

echo ""
echo "==========================="
if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}Compatibility check FAILED with $ERRORS error(s)${NC}"
    echo "Silimon cannot be installed on this system."
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}Compatibility check passed with $WARNINGS warning(s)${NC}"
    echo "Silimon can be installed but some features may not work."
    exit 0
else
    echo -e "${GREEN}Compatibility check PASSED${NC}"
    echo "Your system meets all requirements for Silimon."
    exit 0
fi
