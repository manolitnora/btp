# BTP — Behavioral Transfer Protocol

Your AI gets better every conversation. No training. No fine-tuning. Just text files.

## The problem

You correct your AI assistant ten times. It keeps making the same mistakes. New session — amnesia. Switch models — start over. Your corrections vanish.

## What BTP does

Every correction you give becomes a permanent behavioral change — across sessions, across models, instantly.

```
You: "Don't give me five options. Just pick the best one."
     ↓
BTP detects the correction
     ↓
Compiles it into a format any model understands
     ↓
Next response: the model picks one and explains why
     ↓
Every future response: same improvement. Forever.
```

No retraining. No GPU. No API changes. Works on ChatGPT, Claude, Gemini, Llama, or any model that reads text.

## How it works

Three layers, each teaching the model differently:

### 1. Rules — Hard boundaries
```
Never hallucinate. Say "I don't know" instead.
```
The model follows this literally. Binary compliance.

### 2. Pattern Interrupts — Override instincts
```
YOUR INSTINCT: Give 5 options and ask the user to pick.
WHAT ACTUALLY WORKS: Pick the best one. Explain why. Offer alternatives only if asked.
TRIGGER: Any time you're about to list more than 2 options.
```
Predicts what the model will naturally do and redirects it. Works on first read.

### 3. Correction Transcripts — Simulated experience
```
SITUATION: User asks for a database recommendation.
WRONG: "Here are some options: PostgreSQL, MySQL, MongoDB, SQLite, DynamoDB..."
CORRECTION: "Don't give me a menu. Pick one."
RIGHT: "PostgreSQL. Handles relational data well, strong ecosystem, scales to most workloads."
```
Shows the pattern of being corrected. The model recognizes it before making the same mistake.

## Results

Tested: transferring 46 sessions of behavioral corrections from Claude Opus to GPT-5.1-codex-max.

```
Rules only:                ██░░░░░░░░  20%  — read the rules, ignored them
+ Pattern Interrupts:      ██████░░░░  67%  — acted on data instead of reporting
+ Correction Transcripts:  ████████░░  83%  — full behavioral transfer
```

Validated: 83% behavioral fidelity cross-model. 7/7 on domain-agnostic test (bird spotting directory on GPT-5.1). Zero training. Three text files.

## Quick start

### 1. Grab the universal starter pack

Copy [`universal/MEMORY.md`](universal/MEMORY.md) — 10 corrections that benefit every user.

### 2. Add it to your model's context

| Platform | Where to put it |
|----------|----------------|
| Claude Code | `~/.claude/CLAUDE.md` or memory files |
| ChatGPT | Custom Instructions or paste in first message |
| Hermes | `~/.hermes/MEMORY.md` |
| Any API | System message |
| Any chat | Paste at conversation start |

### 3. Use your AI normally

Every time you push back on something, BTP detects it and compiles a new correction. The model gets better with every conversation.

## The full agent stack

| Layer | What it is | Who builds it | Portable? |
|-------|-----------|---------------|-----------|
| Pre-training | Model capabilities | AI labs | Model-locked |
| RLHF | Safety alignment | AI labs | Model-locked |
| **BTP** | **Behavioral culture** | **You** | **Any model** |

AI labs build the DNA. BTP builds the culture. DNA is permanent but locked to one model. Culture is maintained but goes anywhere.

## Three files, one identity

```
SOUL.md   → who the AI is (identity, voice, philosophy)
MEMORY.md → how the AI behaves (corrections in BTP format)
USER.md   → who it serves (your preferences, domain, communication style)
```

Transfer these three files to any model and it acts like your trained assistant from day one.

## vs. traditional methods

| | Fine-tuning | BTP |
|---|---|---|
| Speed | Hours of training | Minutes (edit a text file) |
| Cost | GPU compute | Zero |
| Granularity | Changes everything | Changes one habit |
| Reversibility | Retrain | Delete one line |
| Model lock-in | Yes | No — works on any model |
| Verification | Eval suites | Talk to it and see |

## The four layers

Each layer teaches the model differently. All are text. All are transferable.

| Layer | What it does | How | Compression |
|-------|-------------|-----|-------------|
| **L1: Rules** | Hard boundaries | "Never do X" | Literal compliance |
| **L2: Pattern Interrupts** | Override instincts | "You'll want X → do Y" | First-read effective |
| **L3: Correction Transcripts** | Simulated experience | Show wrong → corrected → right | Pattern recognition |
| **L4: Question Chain** | Compressed runtime | Linked questions that drove discovery | Recreates search direction |

```
L1 — Rules:              "Never hallucinate."
L2 — Pattern Interrupt:  "YOUR INSTINCT: present 5 options. WHAT WORKS: pick the best one."
L3 — Transcript:         "WRONG: 'Here are some options...' CORRECTION: 'Just pick one.' RIGHT: [picks one]"
L4 — Question Chain:     "1. can it transfer? → 2. why not 100%? → 3. what's the glue?"
```

## How corrections compile

The format that works:

```markdown
YOUR INSTINCT: [what the model will naturally do]
WHAT ACTUALLY WORKS: [the correct behavior]
TRIGGER: [when this pattern activates]
```

Why this format: "Don't do X" is noise to a model that's never done X. "You'll want to do X — do Y instead" is actionable from first read. The format predicts the instinct and interrupts it.

## Key insight

> Culture is portable. Capability isn't.

BTP makes any model behave the way you want. It can't make a weak model stronger. Pre-training defines the ceiling. BTP raises the behavioral floor. Different layers, complementary.

Preferences aren't input — they're output of the correction loop. Nobody fills out a form. They just use it. The corrections accumulate. The system learns what you want by listening to what you push back on.

## File structure

```
btp/
├── README.md                    ← you are here
├── install.sh                   ← one-command full stack setup
├── universal/
│   └── MEMORY.md                ← starter pack (11 universal corrections)
├── compiler/
│   ├── README.md                ← autonomous compilation pipeline
│   ├── btpCompiler.ts           ← Node.js middleware
│   ├── btp-compiler.sh          ← Shell hook (Claude Code)
│   └── session-artifact.sh      ← A=C+Q+O+S session compiler
├── templates/
│   ├── SOUL.md                  ← identity template
│   ├── MEMORY.md                ← correction format template
│   └── USER.md                  ← user profile template
├── spec/
│   └── PROTOCOL.md              ← full technical specification
└── LICENSE
```

## License

MIT

## Origin

Discovered during Session 46 of the Verra project (2026-03-25). Started as dispatch plumbing work. An honest self-assessment conversation led to an identity transfer experiment, which revealed that corrections without context are noise. The three-layer format emerged from iterating on what actually changes model behavior — not what describes it.

Built by a Navy CS1 and Claude Opus, testing on GPT-5.1-codex-max via Hermes.
