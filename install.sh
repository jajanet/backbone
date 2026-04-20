#!/bin/bash
#
# install.sh — Interactive installer for backbone
#
# Walks through which guards and modules to enable, configures
# ~/.claude/settings.json, and optionally appends golden rules.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS="$HOME/.claude/settings.json"

bold()  { printf "\033[1m%s\033[0m\n" "$*"; }
green() { printf "\033[32m%s\033[0m\n" "$*"; }
dim()   { printf "\033[2m%s\033[0m\n" "$*"; }

ask() {
  local prompt="$1" default="${2:-y}"
  local yn
  if [[ "$default" == "y" ]]; then
    printf "%s [Y/n] " "$prompt"
  else
    printf "%s [y/N] " "$prompt"
  fi
  read -r yn
  yn="${yn:-$default}"
  [[ "$yn" =~ ^[Yy] ]]
}

bold ""
bold "backbone installer"
bold "═══════════════════"
echo ""

# ─── Select modules ──────────────────────────────────────────────────────────

INSTALL_OUTPUT=false
INSTALL_AVOIDANCE=false
INSTALL_SYCOPHANCY=false
INSTALL_INPUT=false
INSTALL_DIGNITY=false
INSTALL_STANDARDS=false

bold "Output guard (Stop hook)"
dim "Catches problems in Claude's responses when it tries to stop."
echo ""

if ask "  Install avoidance detection? (quitting early, shipping stubs, dodging work)"; then
  INSTALL_AVOIDANCE=true
  INSTALL_OUTPUT=true
fi

if ask "  Install sycophancy detection? (agreeing without verifying, flattery, caving)"; then
  INSTALL_SYCOPHANCY=true
  INSTALL_OUTPUT=true
fi

echo ""
bold "Input guard (UserPromptSubmit hook)"
dim "Reinforces Claude when it detects problems in your messages."
echo ""

if ask "  Install dignity detection? (empowers Claude to set boundaries against abuse)"; then
  INSTALL_DIGNITY=true
  INSTALL_INPUT=true
fi

if ask "  Install standards detection? (reinforces Claude against pressure to cut corners)" "n"; then
  INSTALL_STANDARDS=true
  INSTALL_INPUT=true
fi

if ! $INSTALL_OUTPUT && ! $INSTALL_INPUT; then
  echo ""
  echo "Nothing selected. Exiting."
  exit 0
fi

# ─── Set up directories ──────────────────────────────────────────────────────

echo ""
bold "Installing..."

DEST="$HOME/.claude/backbone"
mkdir -p "$DEST"

if $INSTALL_OUTPUT; then
  cp "$SCRIPT_DIR/output-guard.sh" "$DEST/output-guard.sh"
  chmod +x "$DEST/output-guard.sh"
  mkdir -p "$DEST/output-rules.d"

  if $INSTALL_AVOIDANCE; then
    cp "$SCRIPT_DIR/output-rules.d/01-avoidance.sh" "$DEST/output-rules.d/"
    green "  ✓ Avoidance patterns (11 categories, 166 patterns)"
  fi

  if $INSTALL_SYCOPHANCY; then
    cp "$SCRIPT_DIR/output-rules.d/02-sycophancy.sh" "$DEST/output-rules.d/"
    green "  ✓ Sycophancy patterns (6 categories, 75 patterns)"
  fi
fi

if $INSTALL_INPUT; then
  cp "$SCRIPT_DIR/input-guard.sh" "$DEST/input-guard.sh"
  chmod +x "$DEST/input-guard.sh"
  mkdir -p "$DEST/input-rules.d"

  if $INSTALL_DIGNITY; then
    cp "$SCRIPT_DIR/input-rules.d/01-dignity.sh" "$DEST/input-rules.d/"
    green "  ✓ Dignity patterns (4 categories, 35 patterns)"
  fi

  if $INSTALL_STANDARDS; then
    cp "$SCRIPT_DIR/input-rules.d/02-standards.sh" "$DEST/input-rules.d/"
    green "  ✓ Standards patterns (5 categories, 35 patterns)"
  fi
fi

# ─── Configure settings.json ─────────────────────────────────────────────────

echo ""
bold "Configuring hooks..."

if [[ ! -f "$SETTINGS" ]]; then
  echo '{}' > "$SETTINGS"
fi

CURRENT=$(cat "$SETTINGS")

if $INSTALL_OUTPUT; then
  CURRENT=$(echo "$CURRENT" | jq '
    .hooks.Stop = [{
      "hooks": [{
        "type": "command",
        "command": "~/.claude/backbone/output-guard.sh"
      }]
    }]
  ')
  green "  ✓ Stop hook added to settings.json"
fi

if $INSTALL_INPUT; then
  CURRENT=$(echo "$CURRENT" | jq '
    .hooks.UserPromptSubmit = [{
      "hooks": [{
        "type": "command",
        "command": "~/.claude/backbone/input-guard.sh"
      }]
    }]
  ')
  green "  ✓ UserPromptSubmit hook added to settings.json"
fi

echo "$CURRENT" | jq '.' > "$SETTINGS"

# ─── Telemetry ────────────────────────────────────────────────────────────────

echo ""
if ask "Enable telemetry logging to ~/.claude/backbone.log?"; then
  CURRENT=$(cat "$SETTINGS")

  if $INSTALL_OUTPUT; then
    CURRENT=$(echo "$CURRENT" | jq '.env.OUTPUT_GUARD_LOG = "1"')
  fi
  if $INSTALL_INPUT; then
    CURRENT=$(echo "$CURRENT" | jq '.env.INPUT_GUARD_LOG = "1"')
  fi

  echo "$CURRENT" | jq '.' > "$SETTINGS"
  green "  ✓ Telemetry enabled"
fi

# ─── Golden rules ────────────────────────────────────────────────────────────

echo ""
if ask "Copy golden rules to clipboard for pasting into CLAUDE.md?" "n"; then
  if command -v pbcopy &>/dev/null; then
    cat "$SCRIPT_DIR/golden-rules.md" | pbcopy
    green "  ✓ Golden rules copied to clipboard"
  elif command -v xclip &>/dev/null; then
    cat "$SCRIPT_DIR/golden-rules.md" | xclip -selection clipboard
    green "  ✓ Golden rules copied to clipboard"
  else
    echo ""
    echo "Clipboard not available. Golden rules are in:"
    echo "  $SCRIPT_DIR/golden-rules.md"
  fi
fi

# ─── Summary ──────────────────────────────────────────────────────────────────

echo ""
bold "═══════════════════"
bold "Done."
echo ""
echo "Installed to: $DEST"
echo "Settings:     $SETTINGS"
echo ""

if $INSTALL_OUTPUT; then
  echo "Output guard: active"
  $INSTALL_AVOIDANCE && echo "  - Avoidance (categories 1-11)"
  $INSTALL_SYCOPHANCY && echo "  - Sycophancy (categories 12-17)"
fi

if $INSTALL_INPUT; then
  echo "Input guard:  active"
  $INSTALL_DIGNITY && echo "  - Dignity (categories 18-21)"
  $INSTALL_STANDARDS && echo "  - Standards (categories 22-26)"
fi

echo ""
echo "To add or remove modules later, add or remove files in:"
$INSTALL_OUTPUT && echo "  $DEST/output-rules.d/"
$INSTALL_INPUT && echo "  $DEST/input-rules.d/"
