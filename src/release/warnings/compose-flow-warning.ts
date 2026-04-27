import type { FlowViolation } from "../flow/violation-taxonomy";
import type { FlowWarningPayload } from "./types";

const WORD_LIMIT = 60;
const SENTENCE_LIMIT = 2;

function toTargetState(fromPhase: string, toPhase: string): string {
  return `${fromPhase}->${toPhase}`;
}

function toMissingAgent(expectedAgent: string): string | null {
  return expectedAgent === "n/a" ? null : expectedAgent;
}

function enforceMessageLimits(message: string): string {
  const normalized = message.replace(/\s+/g, " ").trim();
  const words = normalized.length === 0 ? [] : normalized.split(" ");
  if (words.length > WORD_LIMIT) {
    return `${words.slice(0, WORD_LIMIT).join(" ")}.`;
  }

  const sentenceCount = (normalized.match(/[.!?](?:\s|$)/g) ?? []).length;
  if (sentenceCount <= SENTENCE_LIMIT) {
    return normalized;
  }

  let keptSentences = 0;
  const clipped = normalized.replace(/[^.!?]+[.!?]?/g, (segment) => {
    if (segment.trim().length === 0) {
      return "";
    }

    if (keptSentences >= SENTENCE_LIMIT) {
      return "";
    }

    keptSentences += 1;
    return segment.trimEnd().endsWith(".") ? `${segment.trim()} ` : `${segment.trim()}. `;
  });

  return clipped.trim();
}

function composeMessage(violation: FlowViolation): { message: string; recoveryAction: string } {
  const route = `${violation.fromPhase} -> ${violation.toPhase}`;

  switch (violation.id) {
    case "missing-required-agent":
      return {
        message: `The ${route} transition needs ${violation.expectedAgent}, but ${violation.actualAgent} attempted it. Run ${violation.expectedAgent} for this handoff, then retry the transition.`,
        recoveryAction: `Run ${violation.expectedAgent} for ${route}, then retry.`,
      };
    case "out-of-order-phase":
      return {
        message: `The ${route} transition is out of order for the current workflow. Return to the nearest valid prior phase and then retry the next legal step.`,
        recoveryAction: "Return to the last valid phase and retry a legal next transition.",
      };
    case "skipped-check-in":
      return {
        message: `A required user check-in was skipped before ${route}. Complete the check-in and capture confirmation before rerunning the transition.`,
        recoveryAction: "Run the required check-in and capture user confirmation.",
      };
    case "rejected-gate-ignored":
      return {
        message: `A rejected gate was bypassed during ${route}. Resolve the rejected gate outcome, then rerun the transition after approval.`,
        recoveryAction: "Resolve the rejected gate and rerun after approval.",
      };
    default:
      return {
        message: violation.message,
        recoveryAction: "Resolve the violation details and retry the transition.",
      };
  }
}

export function composeFlowWarning(violation: FlowViolation): FlowWarningPayload {
  const composed = composeMessage(violation);

  return {
    violationId: violation.id,
    message: enforceMessageLimits(composed.message),
    recoveryAction: composed.recoveryAction,
    missingAgent: toMissingAgent(violation.expectedAgent),
    targetState: toTargetState(violation.fromPhase, violation.toPhase),
  };
}
