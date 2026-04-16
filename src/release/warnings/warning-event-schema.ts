import type { ViolationId } from "../flow/violation-taxonomy";

export interface WarningQualityResult {
  passed: boolean;
  evaluatedAt: string;
  evaluationDurationMs: number;
}

export interface WarningQualityChecks {
  messageQuality: WarningQualityResult;
  deliveryQuality: WarningQualityResult;
}

export interface WarningAuditEvent {
  warningId: string;
  violationId: ViolationId;
  message: string;
  recoveryAction: string;
  missingAgent: string | null;
  targetState: string;
  detectedAt: string;
  displayedAt: string;
  interactionTurnId: string | null;
  deliveryMode: "same-turn";
  qualityPassed: boolean;
  qualityChecks: WarningQualityChecks;
  totalQualityDurationMs: number;
  recordedAt: string;
}

export interface BuildWarningAuditEventInput
  extends Omit<WarningAuditEvent, "qualityPassed" | "totalQualityDurationMs" | "recordedAt"> {
  recordedAt?: string;
}

export function buildWarningAuditEvent(input: BuildWarningAuditEventInput): WarningAuditEvent {
  const qualityPassed = input.qualityChecks.messageQuality.passed && input.qualityChecks.deliveryQuality.passed;
  const totalQualityDurationMs =
    input.qualityChecks.messageQuality.evaluationDurationMs +
    input.qualityChecks.deliveryQuality.evaluationDurationMs;

  return {
    ...input,
    qualityPassed,
    totalQualityDurationMs,
    recordedAt: input.recordedAt ?? new Date().toISOString(),
  };
}
