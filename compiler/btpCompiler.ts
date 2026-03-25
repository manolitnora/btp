/**
 * BTP Compiler — Auto-detects corrections and compiles them into
 * Behavioral Transfer Protocol format.
 *
 * The user just talks. This module watches for three signals:
 *   1. Explicit: "don't", "stop", "no", "not that"
 *   2. Implicit: user rephrases what the assistant said
 *   3. Behavioral: user ignores suggestion and does something else
 *
 * When detected, compiles into BTP three-layer format and writes
 * to VERRA.md for instant application on the next message.
 *
 * No user action needed. The system learns invisibly.
 */

import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

// ═══════════════════════════════════════════════════════════════════
// CORRECTION DETECTION
// ═══════════════════════════════════════════════════════════════════

// Explicit correction signals in user messages
const EXPLICIT_PATTERNS = [
    /\b(don't|dont|do not|stop|never|quit)\b.*\b(do|say|give|ask|show|report|list|suggest|present)\b/i,
    /\b(no|nope|nah)\b[,.]?\s*(just|instead|rather)/i,
    /\b(not that|not like that|wrong|incorrect)\b/i,
    /\b(I said|I meant|I asked for|what I want)\b/i,
    /\b(skip|drop|cut|remove)\b.*\b(the|that|this)\b/i,
];

// Implicit correction: user is correcting framing/approach
const IMPLICIT_PATTERNS = [
    /\b(actually|what I mean is|let me clarify|to be clear)\b/i,
    /\b(no no|nono|no,? no)\b/i,
    /\b(that's not|thats not|it's not|its not)\b.*\b(what|how|right)\b/i,
];

interface CorrectionSignal {
    type: 'explicit' | 'implicit' | 'behavioral';
    userMessage: string;
    assistantResponse: string;
    confidence: number;
}

/**
 * Detect if a user message contains a correction signal.
 * Returns null if no correction detected.
 */
export function detectCorrection(
    userMessage: string,
    previousAssistantResponse: string | null,
): CorrectionSignal | null {
    const msg = userMessage.trim();

    // Skip very short messages that aren't corrections
    if (msg.length < 5) return null;

    // Check explicit patterns
    for (const pattern of EXPLICIT_PATTERNS) {
        if (pattern.test(msg)) {
            return {
                type: 'explicit',
                userMessage: msg,
                assistantResponse: previousAssistantResponse ?? '',
                confidence: 0.8,
            };
        }
    }

    // Check implicit patterns
    for (const pattern of IMPLICIT_PATTERNS) {
        if (pattern.test(msg)) {
            return {
                type: 'implicit',
                userMessage: msg,
                assistantResponse: previousAssistantResponse ?? '',
                confidence: 0.6,
            };
        }
    }

    return null;
}

// ═══════════════════════════════════════════════════════════════════
// BTP COMPILATION — Turn raw correction into three-layer format
// ═══════════════════════════════════════════════════════════════════

interface BTPEntry {
    instinct: string;
    whatWorks: string;
    trigger: string;
    transcript: {
        situation: string;
        wrong: string;
        correction: string;
        right: string;
    };
}

/**
 * Compile a correction signal into BTP format.
 * Uses the assistant's previous response as "what went wrong"
 * and the user's correction as the redirect.
 */
export function compileBTP(signal: CorrectionSignal): BTPEntry {
    const wrongBehavior = signal.assistantResponse.slice(0, 150).trim();
    const correction = signal.userMessage.slice(0, 200).trim();

    // Extract the instinct from what the assistant did
    const instinct = wrongBehavior
        ? `Respond with: "${wrongBehavior.split('\n')[0].slice(0, 100)}"`
        : 'Default behavior that was corrected';

    // Extract what works from the correction
    const whatWorks = correction;

    return {
        instinct,
        whatWorks,
        trigger: 'Similar conversational context',
        transcript: {
            situation: 'During conversation',
            wrong: wrongBehavior.split('\n')[0].slice(0, 120) || 'Previous response',
            correction,
            right: `[Adjusted behavior per correction]`,
        },
    };
}

/**
 * Format a BTP entry as markdown for VERRA.md injection.
 */
export function formatBTPMarkdown(entry: BTPEntry): string {
    return `
## Auto-learned correction

YOUR INSTINCT: ${entry.instinct}
WHAT ACTUALLY WORKS: ${entry.whatWorks}
TRIGGER: ${entry.trigger}

### Correction transcript
\`\`\`
SITUATION: ${entry.transcript.situation}
WRONG: ${entry.transcript.wrong}
CORRECTION: ${entry.transcript.correction}
RIGHT: ${entry.transcript.right}
\`\`\`
`;
}

// ═══════════════════════════════════════════════════════════════════
// STORAGE — Write compiled BTP to VERRA.md
// ═══════════════════════════════════════════════════════════════════

const BTP_SECTION_MARKER = '═══ BTP AUTO-LEARNED CORRECTIONS ═══';
const MAX_AUTO_CORRECTIONS = 20;

/**
 * Append a compiled BTP correction to VERRA.md.
 * Maintains a capped section — oldest corrections rotate out.
 */
export function appendToVerraMd(entry: BTPEntry, projectRoot: string): boolean {
    const verraMdPath = join(projectRoot, 'VERRA.md');

    try {
        let content = existsSync(verraMdPath)
            ? readFileSync(verraMdPath, 'utf-8')
            : '';

        const btpMarkdown = formatBTPMarkdown(entry);

        // Find or create the BTP section
        const markerIndex = content.indexOf(BTP_SECTION_MARKER);

        if (markerIndex === -1) {
            // First correction — create the section
            content += `\n\n${BTP_SECTION_MARKER}\n${btpMarkdown}`;
        } else {
            // Append to existing section
            const beforeMarker = content.slice(0, markerIndex + BTP_SECTION_MARKER.length);
            const afterMarker = content.slice(markerIndex + BTP_SECTION_MARKER.length);

            // Count existing auto-corrections
            const correctionCount = (afterMarker.match(/## Auto-learned correction/g) || []).length;

            if (correctionCount >= MAX_AUTO_CORRECTIONS) {
                // Remove the oldest correction (first one after marker)
                const firstCorrectionEnd = afterMarker.indexOf('## Auto-learned correction', 1);
                if (firstCorrectionEnd > 0) {
                    content = beforeMarker + afterMarker.slice(firstCorrectionEnd) + btpMarkdown;
                } else {
                    content = beforeMarker + btpMarkdown;
                }
            } else {
                content = beforeMarker + afterMarker + btpMarkdown;
            }
        }

        writeFileSync(verraMdPath, content, 'utf-8');
        return true;
    } catch {
        return false;
    }
}

// ═══════════════════════════════════════════════════════════════════
// MAIN PIPELINE — Wire into chat handler
// ═══════════════════════════════════════════════════════════════════

let lastAssistantResponse: string | null = null;
let compiledCount = 0;

/**
 * Process a chat exchange for BTP corrections.
 * Call this after every user message + assistant response pair.
 *
 * Returns true if a correction was detected and compiled.
 */
export function processChatForBTP(
    userMessage: string,
    assistantResponse: string,
    projectRoot: string,
): boolean {
    // Detect correction in user's message (comparing to previous assistant response)
    const signal = detectCorrection(userMessage, lastAssistantResponse);

    // Update last response for next round
    lastAssistantResponse = assistantResponse;

    if (!signal) return false;
    if (signal.confidence < 0.6) return false;

    // Compile and store
    const entry = compileBTP(signal);
    const stored = appendToVerraMd(entry, projectRoot);

    if (stored) {
        compiledCount++;
        console.error(`[btp] correction #${compiledCount} compiled: "${signal.userMessage.slice(0, 50)}..."`);
    }

    return stored;
}

/**
 * Get BTP compiler stats.
 */
export function getBTPStats(): { compiledCount: number } {
    return { compiledCount };
}
