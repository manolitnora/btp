# BTP Compiler — Autonomous Behavioral Learning

Detects corrections in conversation. Compiles them into BTP format. Stores them for instant application. No user action needed.

## How it works

```
User talks normally
       ↓
Compiler watches every exchange
       ↓
Detects correction signals:
  - Explicit: "don't do that", "stop", "no"
  - Implicit: user rephrases your answer
  - Contradiction: "actually", "wait", "I meant"
       ↓
Compiles into BTP three-layer format:
  - Pattern interrupt (instinct → override → trigger)
  - Correction transcript (situation → wrong → correction → right)
       ↓
Writes to memory file (MEMORY.md, VERRA.md, vault, or any store)
       ↓
Next response already has the correction applied
```

The user never knows this is happening. They just talk. The AI gets better.

## Integration

### Option A: Post-response hook (Claude Code, any hook-supporting system)

```bash
# Add to your Stop/post-response hook
./btp-compiler.sh
```

The hook reads the conversation transcript, detects corrections, compiles BTP format, appends to memory file.

### Option B: Chat handler middleware (Node.js/TypeScript)

```typescript
import { processChatForBTP } from './btpCompiler';

// After every chat exchange:
processChatForBTP(userMessage, assistantResponse, projectRoot);
```

### Option C: Standalone CLI

```bash
# Process a transcript file
./btp-compile --transcript conversation.json --output corrections.md
```

## Files

```
compiler/
├── README.md           ← you are here
├── btpCompiler.ts      ← TypeScript module (Node.js chat handlers)
├── btp-compiler.sh     ← Shell hook (Claude Code, any CLI)
├── detect.ts           ← Correction detection patterns
└── compile.ts          ← BTP format compilation
```

## Detection Patterns

### Explicit (high confidence: 0.8)
- "don't/stop/never [verb]"
- "no, just/instead/rather"
- "not that/wrong/incorrect"
- "skip/drop/cut/remove"

### Implicit (medium confidence: 0.6)
- "actually/what I mean is/to be clear"
- "no no" (repeated negation)
- "that's not what/how"

### Behavioral (requires previous response comparison)
- User rephrases assistant's output (semantic similarity + different words)
- User ignores suggestion and does something else
- Short dismissive response after long assistant output

## Configuration

```bash
# Environment variables
OLLAMA_ENDPOINT=http://localhost:11434   # Local LLM for compilation
BTP_MODEL=qwen2.5:7b                     # Any Ollama model
BTP_MAX_CORRECTIONS=20                   # Cap per file (oldest rotate out)
BTP_MIN_CONFIDENCE=0.6                   # Detection threshold
```

## No Ollama? No problem.

The compiler works without a local LLM — it uses regex detection and template-based compilation. The LLM adds better compilation quality but isn't required. Regex detection + template output gets you 70% of the value at zero cost.

## Requirements

- A chat system that gives you access to user message + assistant response
- A place to write text (file system, database, API)
- Optional: Ollama for higher-quality compilation
