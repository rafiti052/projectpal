import type { FlowViolation } from "../flow/violation-taxonomy";
import type {
  PhaseAgentRule,
  ValidationContext,
} from "../flow/phase-agent-rule";
import { validatePhaseAgentTransition } from "../flow/phase-agent-rule";

export interface PhaseTransitionValidationResult {
  ok: boolean;
  violation: FlowViolation | null;
}

export function validatePhaseTransition(
  context: ValidationContext,
  rules?: PhaseAgentRule[],
): PhaseTransitionValidationResult {
  const result = validatePhaseAgentTransition(context, rules);

  return {
    ok: result.allowed,
    violation: result.violation ?? null,
  };
}
