---
name: screenshot-widget
description: Take a screenshot of the Silimon menu bar widget popover. Use when the user asks to screenshot, capture, or view the Silimon widget, popover, or UI.
allowed-tools: Bash, Read
---

# Screenshot Silimon Widget

Take a screenshot of the Silimon menu bar widget popover.

## Instructions

Run these commands in order:

1. **Open the widget and capture it**:

```bash
REPO_ROOT="$(git rev-parse --show-toplevel)" && osascript -e 'tell application "System Events" to click menu bar item 1 of menu bar 1 of application process "silimon"' && sleep 0.3 && WINDOW_ID=$(swift "$REPO_ROOT/.claude/skills/screenshot-widget/listwindows.swift" 2>/dev/null | grep "Window ID:" | head -1 | sed 's/Window ID: \([0-9]*\).*/\1/') && screencapture -l$WINDOW_ID /tmp/silimon-widget.png
```

2. **View the screenshot** using the Read tool on `/tmp/silimon-widget.png`

## Files

- `listwindows.swift` - Swift script that uses CGWindowListCopyWindowInfo to find Silimon's popover window ID

## Notes

- Requires Accessibility permissions for the terminal/Claude Code
- The widget must be closed before running (clicking toggles it open/closed)
- Screenshot is saved to `/tmp/silimon-widget.png`
