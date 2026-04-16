export {
  validatePhaseTransition,
  type PhaseTransitionValidationResult,
} from "./validate-phase-transition";
import type { PhaseAgentRule, ValidationContext } from "../flow/phase-agent-rule";
import type { FlowViolation } from "../flow/violation-taxonomy";
import {
  emitWarning,
  type EmittedFlowWarning,
  type FlowWarningPayload,
} from "../warnings/emit-warning";
import { validatePhaseTransition } from "./validate-phase-transition";
import type { PhaseTransitionValidationResult } from "./validate-phase-transition";

export interface ValidateAndEmitWarningContext {
  transition: ValidationContext;
  rules?: PhaseAgentRule[];
  warning?: FlowWarningPayload;
  detectedAt?: Date;
  interactionTurnId?: string;
}

export interface ValidateAndEmitWarningResult extends PhaseTransitionValidationResult {
  warning: EmittedFlowWarning | null;
}

function buildWarningFromViolation(violation: FlowViolation): FlowWarningPayload {
  return {
    message: violation.message,
    recoveryAction: `Use ${violation.expectedAgent} for this transition and retry.`,
    missingAgent: violation.expectedAgent,
    targetState: `${violation.fromPhase} -> ${violation.toPhase}`,
  };
}

export function validatePhaseTransitionAndEmitWarning(
  context: ValidateAndEmitWarningContext,
): ValidateAndEmitWarningResult {
  const validation = validatePhaseTransition(context.transition, context.rules);

  if (validation.ok || !validation.violation) {
    return {
      ...validation,
      warning: null,
    };
  }

  const warning = emitWarning({
    violation: validation.violation,
    warning: context.warning ?? buildWarningFromViolation(validation.violation),
    detectedAt: context.detectedAt,
    interactionTurnId: context.interactionTurnId,
  });

  return {
    ...validation,
    warning,
  };
}
