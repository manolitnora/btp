#!/bin/bash
# BTP Auto-Compiler for Claude Code
# Runs as a Stop hook — fires after every assistant response.
# Reads transcript_path from stdin, extracts last user+assistant turn,
# detects corrections, compiles BTP format via Ollama, writes to memory.

OLLAMA_ENDPOINT="${OLLAMA_ENDPOINT:-http://localhost:11434}"
MODEL="${BTP_MODEL:-qwen2.5:7b}"
MEMORY_DIR="$HOME/.claude/projects/-Users-$(whoami)/memory"
BTP_LOG="/tmp/btp-compiler.log"

# Read hook input from stdin
INPUT=$(cat)

# Extract transcript_path from JSON
TRANSCRIPT=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('transcript_path', ''))
except:
    pass
" 2>/dev/null)

[ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ] && exit 0

# Extract last user message and assistant response from transcript
LAST_TURNS=$(python3 -c "
import json, sys

try:
    with open('$TRANSCRIPT', 'r') as f:
        data = json.load(f)

    messages = data if isinstance(data, list) else data.get('messages', data.get('turns', []))
    if not messages or len(messages) < 2:
        sys.exit(0)

    # Find last user and last assistant
    user_msg = ''
    asst_msg = ''
    for m in reversed(messages):
        role = m.get('role', '')
        content = m.get('content', '')
        if isinstance(content, list):
            content = ' '.join(c.get('text', '') for c in content if isinstance(c, dict))
        if role == 'assistant' and not asst_msg:
            asst_msg = content[:200]
        elif role == 'user' and not user_msg:
            user_msg = content[:200]
        if user_msg and asst_msg:
            break

    if not user_msg:
        sys.exit(0)

    print(json.dumps({'user': user_msg, 'assistant': asst_msg}))
except:
    sys.exit(0)
" 2>/dev/null)

[ -z "$LAST_TURNS" ] && exit 0

USER_MSG=$(echo "$LAST_TURNS" | python3 -c "import sys,json; print(json.load(sys.stdin)['user'])" 2>/dev/null)
ASST_MSG=$(echo "$LAST_TURNS" | python3 -c "import sys,json; print(json.load(sys.stdin)['assistant'])" 2>/dev/null)

[ -z "$USER_MSG" ] && exit 0

# Quick regex check — is this likely a correction?
if ! echo "$USER_MSG" | grep -qiE "(don.t|stop|never|no |not that|wrong|actually|I meant|I said|skip|cut|remove|nope|nah|instead)"; then
    exit 0
fi

# Call Ollama to detect and compile
PROMPT="Is this user message correcting the AI? If YES, output a BTP correction. If NO, output just NONE.

User said: $USER_MSG

AI previously said: $ASST_MSG

If correction, output exactly:
INSTINCT: [what the AI naturally did wrong]
WORKS: [what the user wants instead]
TRIGGER: [when this applies]"

RESPONSE=$(curl -s --max-time 10 "$OLLAMA_ENDPOINT/api/chat" \
    -H "Content-Type: application/json" \
    -d "$(python3 -c "
import json
print(json.dumps({
    'model': '$MODEL',
    'stream': False,
    'messages': [{'role': 'user', 'content': '''$PROMPT'''}],
    'options': {'temperature': 0, 'num_predict': 100}
}))
" 2>/dev/null)" 2>/dev/null)

CONTENT=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('message',{}).get('content','NONE'))" 2>/dev/null)

# If not a correction, exit
[ -z "$CONTENT" ] && exit 0
echo "$CONTENT" | grep -qi "^NONE" && exit 0
echo "$CONTENT" | grep -qi "INSTINCT" || exit 0

# Write to BTP corrections file
BTP_FILE="$MEMORY_DIR/btp_auto_corrections.md"

if [ ! -f "$BTP_FILE" ]; then
    cat > "$BTP_FILE" << 'HEADER'
---
name: btp_auto_corrections
description: Auto-compiled behavioral corrections — pattern interrupts detected by local LLM from conversation
type: feedback
---

# Auto-Compiled BTP Corrections
HEADER
fi

# Count existing corrections — cap at 20
EXISTING=$(grep -c "^## " "$BTP_FILE" 2>/dev/null || echo 0)
if [ "$EXISTING" -ge 20 ]; then
    # Remove oldest (first correction after header)
    python3 -c "
import re
with open('$BTP_FILE', 'r') as f:
    content = f.read()
parts = re.split(r'(?=^## \d)', content, flags=re.MULTILINE)
if len(parts) > 2:
    # Keep header + all but first correction
    result = parts[0] + ''.join(parts[2:])
    with open('$BTP_FILE', 'w') as f:
        f.write(result)
" 2>/dev/null
fi

# Append new correction
{
    echo ""
    echo "## $(date '+%Y-%m-%d %H:%M')"
    echo ""
    echo "$CONTENT"
    echo ""
} >> "$BTP_FILE"

echo "[$(date '+%H:%M:%S')] compiled: $(echo "$USER_MSG" | head -c 50)" >> "$BTP_LOG"
exit 0
