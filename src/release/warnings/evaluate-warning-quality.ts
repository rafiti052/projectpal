import {
  WARNING_CLARITY_MAX_SENTENCES,
  WARNING_CLARITY_MAX_WORDS,
  WARNING_GENERIC_FIX_PATTERN,
  WARNING_IMPERATIVE_START_PATTERN,
  WARNING_PLACEHOLDER_PATTERN,
  WARNING_TIMING_MAX_DELTA_MS,
} from "./quality-thresholds";

export interface WarningQualityInput {
  message: string;
  recoveryAction: string;
  missingAgent: string | null;
  targetState: string;
  detectedAt: string;
  displayedAt: string;
}

export interface WarningQualityEvaluation {
  actionabilityPass: boolean;
  clarityPass: boolean;
  timingPass: boolean;
}

function normalizeWhitespace(value: string): string {
  return value.replace(/\s+/g, " ").trim();
}

function countWords(value: string): number {
  const normalized = normalizeWhitespace(value);
  return normalized.length === 0 ? 0 : normalized.split(" ").length;
}

function countSentences(value: string): number {
  return (normalizeWhitespace(value).match(/[.!?](?:\s|$)/g) ?? []).length;
}

function includesTargetState(message: string, recoveryAction: string, targetState: string): boolean {
  const normalizedTarget = targetState.replace(/\s*->\s*/g, "->").toLowerCase();
  const normalizedText = `${message} ${recoveryAction}`.replace(/\s*->\s*/g, "->").toLowerCase();
  return normalizedText.includes(normalizedTarget);
}

function hasSingleImperativeStep(recoveryAction: string): boolean {
  const normalized = normalizeWhitespace(recoveryAction);
  if (!WARNING_IMPERATIVE_START_PATTERN.test(normalized)) {
    return false;
  }

  const sentenceCount = countSentences(normalized);
  return sentenceCount <= 1;
}

function hasRequiredAgentContext(message: string, recoveryAction: string, missingAgent: string | null): boolean {
  const content = `${message} ${recoveryAction}`.toLowerCase();
  if (missingAgent) {
    return content.includes(missingAgent.toLowerCase());
  }

  return /out of order|phase|transition/.test(content);
}

function evaluateActionability(input: WarningQualityInput): boolean {
  return (
    hasSingleImperativeStep(input.recoveryAction) &&
    hasRequiredAgentContext(input.message, input.recoveryAction, input.missingAgent) &&
    includesTargetState(input.message, input.recoveryAction, input.targetState)
  );
}

function evaluateClarity(message: string): boolean {
  const normalized = normalizeWhitespace(message);
  const wordsPass = countWords(normalized) <= WARNING_CLARITY_MAX_WORDS;
  const sentencesPass = countSentences(normalized) <= WARNING_CLARITY_MAX_SENTENCES;
  const placeholdersPass = !WARNING_PLACEHOLDER_PATTERN.test(normalized);
  const genericFixPass = !WARNING_GENERIC_FIX_PATTERN.test(normalized);

  return wordsPass && sentencesPass && placeholdersPass && genericFixPass;
}

function evaluateTiming(detectedAt: string, displayedAt: string): boolean {
  const detectedAtMs = Date.parse(detectedAt);
  const displayedAtMs = Date.parse(displayedAt);
  if (!Number.isFinite(detectedAtMs) || !Number.isFinite(displayedAtMs)) {
    return false;
  }

  const deltaMs = displayedAtMs - detectedAtMs;
  return deltaMs >= 0 && deltaMs <= WARNING_TIMING_MAX_DELTA_MS;
}

export function evaluateWarningQuality(input: WarningQualityInput): WarningQualityEvaluation {
  return {
    actionabilityPass: evaluateActionability(input),
    clarityPass: evaluateClarity(input.message),
    timingPass: evaluateTiming(input.detectedAt, input.displayedAt),
  };
}
