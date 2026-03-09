#!/bin/zsh
# Switch statusline theme
# Usage: ./switch-theme.sh [minimal|cool|neon|default]
# Each theme is self-contained — just copies one file.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$HOME/.claude/statusline.sh"

case "$1" in
  minimal)
    cp "$SCRIPT_DIR/statusline-minimal.sh" "$TARGET"
    echo "Switched to: Minimal Mono (muted, color only for alerts)"
    ;;
  cool)
    cp "$SCRIPT_DIR/statusline-cool.sh" "$TARGET"
    echo "Switched to: Cool Tones (blues, purples, gold accents)"
    ;;
  neon)
    cp "$SCRIPT_DIR/statusline-neon.sh" "$TARGET"
    echo "Switched to: Neon Terminal (high contrast, retro hacker)"
    ;;
  default)
    cp "$SCRIPT_DIR/statusline.sh" "$TARGET"
    echo "Switched to: Default (original colors)"
    ;;
  *)
    echo "Usage: $0 [minimal|cool|neon|default]"
    echo ""
    echo "Themes:"
    echo "  minimal  — Muted mono, color only for warnings"
    echo "  cool     — Blues, purples, gold accents"
    echo "  neon     — High contrast, retro hacker"
    echo "  default  — Original color scheme"
    exit 1
    ;;
esac

chmod +x "$TARGET"
echo "Restart Claude Code or start a new session to see the change."
