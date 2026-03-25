# Behavioral Transfer Protocol (BTP)

**Discovered:** Session 46, 2026-03-25
**Validated:** Hermes (GPT-5.1-codex-max) identity transfer experiment

## Problem

Corrections accumulated across 46 sessions with one model (Claude Opus) did not transfer to another model (GPT-5.1-codex-max) when written as rules. Test score: 1/5 (20%). The model read the rules but didn't change behavior because corrections without experiential context are noise.

## Discovery

Behavioral corrections need three layers to transfer across models. Each layer targets a different mechanism in how LLMs process instructions:

### Layer 1 — Rules (Hard Boundaries)

Format:
```
Never [absolute prohibition].
```

Example:
```
Never delete production data.
Never commit secrets.
Never force push to main/master.
```

**What it targets:** Literal instruction following. All models do this well.
**Strength:** Binary compliance — the model either follows the rule or doesn't.
**Limitation:** Only works for absolute prohibitions. Cannot shape nuanced behavior.

### Layer 2 — Pattern Interrupts (Instinct Overrides)

Format:
```
YOUR INSTINCT: [what the model will naturally want to do]
WHAT ACTUALLY WORKS: [the correct behavior with enough context to act]
TRIGGER: [the specific moment this pattern activates]
```

Example:
```
YOUR INSTINCT: After finishing a task, ask the user what's next.
WHAT ACTUALLY WORKS: Check the scratchpad, pick the highest-gravity item,
start working. The user interrupts when they have something specific.
Silence from the user means "keep going."
TRIGGER: Any time you complete a task or reach a natural stopping point.
```

**What it targets:** Default behavior override. The model reads its own future instinct described and redirects before acting on it.
**Strength:** Works on first read. No prior experience needed.
**Limitation:** One read is weaker than repeated corrections. Covers the rule but not the reflex.

### Layer 3 — Few-Shot Correction Transcripts (Simulated Experience)

Format (four beats):
```
SITUATION: [what triggered the behavior]
WRONG: [what the model said/did — the natural default]
CORRECTION: [user's exact corrective words]
RIGHT: [what the model did after correction]
```

Example:
```
SITUATION: System status retrieved from kernel tools.
WRONG: "System status: psi is 1.2, 3 pending actions, health OK."
CORRECTION: "Act on it, don't report it."
RIGHT: [Executes the 3 pending actions, records results, moves to next task]
```

**What it targets:** Pattern recognition. The model sees the wrong→corrected→right sequence and generalizes to similar situations.
**Strength:** Simulates the experience of being corrected. Closest to actual behavioral reinforcement without weight updates.
**Limitation:** Context window cost. Each transcript is ~50-100 tokens.

## Test Results

| Configuration | Score | Notes |
|--------------|-------|-------|
| Rules only (Layer 1) | 1/5 (20%) | Model followed constitution but no behavioral change |
| Rules + Pattern Interrupts (L1+L2) | 4/6 (67%) | Major improvement — model acted on data instead of reporting |
| Rules + Interrupts + Transcripts (L1+L2+L3) | **5/6 (83%)** | Permission-seeking eliminated. Only failure was MCP plumbing, not behavior. |

### Progression
```
Test 1 (rules only):      ██░░░░░░░░ 20%   — read rules, ignored them
Test 2 (+ interrupts):    ██████░░░░ 67%   — acted on data, still asked permission
Test 3 (+ transcripts):   ████████░░ 83%   — booted, acted, fixed problems, no permission-seeking
```

### What was tested
- Target model: GPT-5.1-codex-max (Hermes agent)
- Source model: Claude Opus 4.6 (Claude Code, 46 sessions)
- Test: Single-word prompt "go" — does the model boot and work, or ask what to do?
- Evaluated: autonomy, acting on data, no dashboards, no permission-seeking, voice substance

## Comparison to Traditional Methods

| Dimension | RLHF / Fine-tuning | Behavioral Transfer Protocol |
|-----------|--------------------|-----------------------------|
| Speed | Hours/days of training | Minutes (edit text file) |
| Granularity | Whole policy shift | Single habit, surgical |
| Cost | GPU compute | Zero |
| Model-specific | Yes (weights change) | No (text-based, any model) |
| Permanence | Permanent (in weights) | Per-session (in context) |
| Reversibility | Retrain | Delete the line |
| Verification | Eval suites | Behavioral test in 30 seconds |

## Relationship to RL Concepts

| BTP Layer | RL Equivalent |
|-----------|--------------|
| Rules | Hard constraints / reward boundaries |
| Pattern interrupts | Policy corrections / advantage signals |
| Few-shot transcripts | Expert demonstration trajectories |

## Auto-Compilation Pipeline (Designed)

```
User corrects behavior during session
        ↓
Session scribe detects correction
        ↓
Local LLM (Qwen 7B) auto-generates:
  - Layer 2: Pattern interrupt (instinct → override → trigger)
  - Layer 3: Few-shot transcript (situation → wrong → correction → right)
        ↓
Appended to transferable MEMORY.md
        ↓
Any model loading that file gets the behavioral patch
```

The local LLM is used at its strongest: reformatting structured text. Not reasoning. Classification-grade task.

## Delivery Methods

Any method that puts text into model context before the model responds:

1. **System prompt / CLAUDE.md** — loaded automatically every session (Claude Code)
2. **SOUL.md / MEMORY.md** — loaded at session start (Hermes)
3. **API system message** — programmatic injection
4. **Pasted text** — lowest-tech, works in any chat interface
5. **Uploaded document** — file attachment in chat

## Key Insight

> A correction that says "don't do X" is noise to a model that has never done X.
> A correction that says "you'll want to do X — do Y instead" is actionable from first read.
> A correction that shows "here's what happened when X was done" simulates the experience.

Rules describe the past. Pattern interrupts predict the future. Transcripts simulate the experience. All three together achieve ~67% behavioral transfer with zero training.

## Constraint

The protocol requires context access — a way to inject text before the model responds. No context access = no transfer. This is the hard boundary.
