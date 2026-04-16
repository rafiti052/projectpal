import type { FlowViolation } from "../flow/violation-taxonomy";

export interface FlowWarningPayload {
  message: string;
  recoveryAction: string;
  missingAgent: string;
  targetState: string;
}

export interface EmitWarningContext {
  violation: FlowViolation;
  warning: FlowWarningPayload;
  detectedAt?: Date;
  interactionTurnId?: string;
}

export interface EmittedFlowWarning {
  violation: FlowViolation;
  warning: FlowWarningPayload;
  detectedAt: string;
  displayedAt: string;
  interactionTurnId: string | null;
  deliveryMode: "same-turn";
}

export function emitWarning(context: EmitWarningContext): EmittedFlowWarning {
  const detectedAt = context.detectedAt ?? new Date();

  return {
    violation: context.violation,
    warning: context.warning,
    detectedAt: detectedAt.toISOString(),
    displayedAt: new Date().toISOString(),
    interactionTurnId: context.interactionTurnId ?? null,
    deliveryMode: "same-turn",
  };
}
