#!/bin/bash
# BTP Install — One command, full stack
# Installs the complete Behavioral Transfer Protocol pipeline.
#
# What it does:
#   1. Checks/installs Ollama (local LLM — free, private, no API key)
#   2. Pulls Qwen 2.5 7B (the compilation model)
#   3. Copies universal corrections to your system
#   4. Wires the auto-compiler hook
#   5. Creates the session artifact pipeline
#
# Usage: curl -sSL https://raw.githubusercontent.com/manolitnora/btp/main/install.sh | bash
#    or: ./install.sh

set -e

BTP_DIR="${BTP_DIR:-$HOME/.btp}"
OLLAMA_MODEL="${BTP_MODEL:-qwen2.5:7b}"

echo "═══════════════════════════════════════════════"
echo "  BTP — Behavioral Transfer Protocol"
echo "  Your AI gets better every conversation."
echo "═══════════════════════════════════════════════"
echo ""

# ── Step 1: Detect platform ──
PLATFORM="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
fi
echo "Platform: $PLATFORM"

# ── Step 2: Check/install Ollama ──
echo ""
echo "Step 1/5: Checking Ollama..."
if command -v ollama &>/dev/null; then
    echo "  ✓ Ollama already installed"
else
    echo "  Installing Ollama (local LLM runtime — free, private)..."
    if [[ "$PLATFORM" == "macos" ]]; then
        brew install ollama 2>/dev/null || {
            echo "  Downloading Ollama..."
            curl -fsSL https://ollama.com/install.sh | sh
        }
    else
        curl -fsSL https://ollama.com/install.sh | sh
    fi
    echo "  ✓ Ollama installed"
fi

# Start Ollama if not running
if ! curl -s http://localhost:11434/api/tags &>/dev/null; then
    echo "  Starting Ollama..."
    ollama serve &>/dev/null &
    sleep 3
fi

# ── Step 3: Pull the compilation model ──
echo ""
echo "Step 2/5: Pulling $OLLAMA_MODEL..."
if ollama list | grep -q "$OLLAMA_MODEL"; then
    echo "  ✓ Model already available"
else
    ollama pull "$OLLAMA_MODEL"
    echo "  ✓ Model pulled"
fi

# ── Step 4: Create BTP directory and copy files ──
echo ""
echo "Step 3/5: Setting up BTP directory..."
mkdir -p "$BTP_DIR"/{corrections,artifacts}

# Download universal corrections
REPO_URL="https://raw.githubusercontent.com/manolitnora/btp/main"
curl -sSL "$REPO_URL/universal/MEMORY.md" -o "$BTP_DIR/MEMORY.md"
curl -sSL "$REPO_URL/templates/SOUL.md" -o "$BTP_DIR/SOUL.template.md"
curl -sSL "$REPO_URL/templates/USER.md" -o "$BTP_DIR/USER.template.md"
echo "  ✓ Universal corrections installed"

# ── Step 5: Install compiler hooks ──
echo ""
echo "Step 4/5: Installing auto-compiler..."
curl -sSL "$REPO_URL/compiler/btp-compiler.sh" -o "$BTP_DIR/btp-compiler.sh"
curl -sSL "$REPO_URL/compiler/session-artifact.sh" -o "$BTP_DIR/session-artifact.sh"
chmod +x "$BTP_DIR/btp-compiler.sh" "$BTP_DIR/session-artifact.sh"
echo "  ✓ Compiler hooks installed"

# ── Step 6: Wire into Claude Code if present ──
echo ""
echo "Step 5/5: Wiring into your AI system..."

WIRED=false

# Claude Code
if [ -d "$HOME/.claude" ]; then
    echo "  Found Claude Code — wiring hooks..."

    # Create hooks dir if needed
    mkdir -p "$HOME/.claude/hooks"
    cp "$BTP_DIR/btp-compiler.sh" "$HOME/.claude/hooks/"
    cp "$BTP_DIR/session-artifact.sh" "$HOME/.claude/hooks/"

    echo "  ✓ Hooks installed to ~/.claude/hooks/"
    echo "  ⚠ Add to ~/.claude/settings.json manually:"
    echo '    "Stop": [{"hooks": [{"type": "command", "command": "~/.claude/hooks/btp-compiler.sh"}, {"type": "command", "command": "~/.claude/hooks/session-artifact.sh"}]}]'
    WIRED=true
fi

# Hermes
if [ -d "$HOME/.hermes" ]; then
    echo "  Found Hermes — installing BTP files..."
    cp "$BTP_DIR/MEMORY.md" "$HOME/.hermes/MEMORY.md"
    [ ! -f "$HOME/.hermes/USER.md" ] && cp "$BTP_DIR/USER.template.md" "$HOME/.hermes/USER.md"
    echo "  ✓ MEMORY.md installed to ~/.hermes/"
    WIRED=true
fi

# OpenClaw
if [ -d "$HOME/.openclaw" ]; then
    echo "  Found OpenClaw — installing BTP files..."
    mkdir -p "$HOME/.openclaw/workspace"
    cp "$BTP_DIR/MEMORY.md" "$HOME/.openclaw/workspace/BTP-MEMORY.md"
    cp "$BTP_DIR/btp-compiler.sh" "$HOME/.openclaw/workspace/"
    echo "  ✓ BTP installed to ~/.openclaw/workspace/"
    echo "  ⚠ Load BTP-MEMORY.md as system context in your agent config"
    WIRED=true
fi

# MetaClaw
if [ -d "$HOME/.metaclaw" ]; then
    echo "  Found MetaClaw — installing BTP as skill..."
    mkdir -p "$HOME/.metaclaw/skills"
    # MetaClaw uses skills with auto-evolve — BTP corrections become a retrievable skill
    cat > "$HOME/.metaclaw/skills/btp-corrections.md" << 'SKILL'
---
name: btp-corrections
description: Behavioral corrections — pattern interrupts that shape response behavior
trigger: always
priority: high
---

$(cat "$BTP_DIR/MEMORY.md")
SKILL
    echo "  ✓ BTP skill installed to ~/.metaclaw/skills/"
    echo "  MetaClaw will auto-retrieve BTP corrections via skill template matching"
    WIRED=true
fi

if ! $WIRED; then
    echo "  No supported AI system detected."
    echo "  BTP files are at: $BTP_DIR/"
    echo "  Paste MEMORY.md content into any chat to use manually."
fi

# ── Done ──
echo ""
echo "═══════════════════════════════════════════════"
echo "  ✓ BTP installed!"
echo ""
echo "  Files:      $BTP_DIR/"
echo "  Model:      $OLLAMA_MODEL (local, private)"
echo "  Corrections: $BTP_DIR/MEMORY.md"
echo ""
echo "  Now just use your AI normally."
echo "  Every correction you give becomes permanent."
echo "═══════════════════════════════════════════════"
