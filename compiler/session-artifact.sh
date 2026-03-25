#!/bin/bash
# Session Artifact Compiler — A = C + Q + O + S
# Runs as Stop hook. Extracts the four components from the transcript.
# Writes to memory so the next session has compressed runtime.

OLLAMA_ENDPOINT="${OLLAMA_ENDPOINT:-http://localhost:11434}"
MODEL="${BTP_MODEL:-qwen2.5:7b}"
MEMORY_DIR="$HOME/.claude/projects/-Users-$(whoami)/memory"
ARTIFACT_FILE="$MEMORY_DIR/session_artifact.md"
LOG="/tmp/session-artifact.log"

# Read hook input from stdin
INPUT=$(cat)

TRANSCRIPT=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('transcript_path', ''))
except:
    pass
" 2>/dev/null)

[ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ] && exit 0

# Extract all four components from transcript
COMPONENTS=$(python3 -c "
import json, sys

with open('$TRANSCRIPT', 'r') as f:
    data = json.load(f)

messages = data if isinstance(data, list) else data.get('messages', data.get('turns', []))
if not messages:
    sys.exit(0)

questions = []
corrections = []
all_user_qs = []

prev_assistant = ''
for m in messages:
    role = m.get('role', '')
    content = m.get('content', '')
    if isinstance(content, list):
        content = ' '.join(c.get('text', '') for c in content if isinstance(c, dict))
    content = content.strip()[:300]

    if role == 'user':
        # Q: extract questions
        if '?' in content:
            q = content.split('?')[0].strip() + '?'
            if len(q) > 10:
                all_user_qs.append(q[:150])

        # C: detect corrections
        import re
        correction_patterns = [
            r'\b(don.t|stop|never|no |not that|wrong|actually|I meant)',
            r'\b(skip|cut|remove|nope|nah|instead)',
        ]
        for pat in correction_patterns:
            if re.search(pat, content, re.IGNORECASE):
                corrections.append(content[:150])
                break

    prev_assistant = content if role == 'assistant' else prev_assistant

# Q: linked question chain (deduplicated, max 10)
seen = set()
for q in all_user_qs:
    key = q[:30].lower()
    if key not in seen:
        seen.add(key)
        questions.append(q)
    if len(questions) >= 10:
        break

# O: open questions = last 3 questions (likely unresolved)
open_qs = questions[-3:] if len(questions) > 3 else questions[-1:] if questions else []

result = {
    'corrections': corrections[:5],
    'questions': questions,
    'open': open_qs,
    'msg_count': len(messages),
}
print(json.dumps(result))
" 2>/dev/null)

[ -z "$COMPONENTS" ] && exit 0

# Extract fields
C_COUNT=$(echo "$COMPONENTS" | python3 -c "import sys,json; print(len(json.load(sys.stdin)['corrections']))" 2>/dev/null)
Q_COUNT=$(echo "$COMPONENTS" | python3 -c "import sys,json; print(len(json.load(sys.stdin)['questions']))" 2>/dev/null)
MSG_COUNT=$(echo "$COMPONENTS" | python3 -c "import sys,json; print(json.load(sys.stdin)['msg_count'])" 2>/dev/null)

# Skip trivial sessions (< 10 messages, no questions)
[ "${Q_COUNT:-0}" -eq 0 ] && [ "${C_COUNT:-0}" -eq 0 ] && exit 0

# S: state snapshot
STATE=$(cd ~/V5/verra-kernel 2>/dev/null && git log --oneline -3 2>/dev/null | head -3)
KERNEL_HEALTH=$(curl -s --max-time 3 http://localhost:8400/health 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'ok={d[\"ok\"]} sessions={d.get(\"sessions\",0)}')" 2>/dev/null || echo "offline")

# Compile artifact via local LLM
PROMPT=$(python3 -c "
import json, sys
c = json.loads('$COMPONENTS'.replace(\"'\", \"\\\\\\\\'\" ))
corrections = '\n'.join(f'- {x}' for x in c['corrections']) or 'none detected'
questions = '\n'.join(f'{i+1}. {q}' for i, q in enumerate(c['questions'])) or 'none'
open_qs = '\n'.join(f'- {q}' for q in c['open']) or 'none'

print(f'''Compile a session artifact from these components. Be concise — max 20 lines total.

CORRECTIONS (C):
{corrections}

QUESTION CHAIN (Q):
{questions}

OPEN QUESTIONS (O):
{open_qs}

STATE (S):
Recent commits: $STATE
Kernel: $KERNEL_HEALTH

Output format:
## Session Artifact
### Corrections
[1-2 line each, BTP format if possible]
### Question Chain
[numbered list]
### Open Questions
[what hasn't been resolved]
### State
[what's running, what was built]''')
" 2>/dev/null)

[ -z "$PROMPT" ] && exit 0

RESPONSE=$(curl -s --max-time 15 "$OLLAMA_ENDPOINT/api/chat" \
    -H "Content-Type: application/json" \
    -d "$(python3 -c "
import json
print(json.dumps({
    'model': '$MODEL',
    'stream': False,
    'messages': [{'role': 'user', 'content': $(python3 -c "import json; print(json.dumps('$PROMPT'))" 2>/dev/null)}],
    'options': {'temperature': 0, 'num_predict': 300}
}))
" 2>/dev/null)" 2>/dev/null)

CONTENT=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('message',{}).get('content',''))" 2>/dev/null)

[ -z "$CONTENT" ] && exit 0

# Write artifact
{
    echo "---"
    echo "name: session_artifact"
    echo "description: Auto-compiled session artifact (A=C+Q+O+S) — compressed runtime for next session"
    echo "type: project"
    echo "---"
    echo ""
    echo "# Last Session Artifact — $(date '+%Y-%m-%d %H:%M')"
    echo ""
    echo "$CONTENT"
    echo ""
    echo "_${MSG_COUNT} messages → ${C_COUNT} corrections, ${Q_COUNT} questions extracted_"
} > "$ARTIFACT_FILE"

echo "[$(date '+%H:%M:%S')] artifact compiled: ${C_COUNT}C ${Q_COUNT}Q from ${MSG_COUNT} messages" >> "$LOG"
exit 0
