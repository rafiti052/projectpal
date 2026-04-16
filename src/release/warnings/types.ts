import type { ViolationId } from "../flow/violation-taxonomy";

export interface FlowWarningPayload {
  violationId: ViolationId;
  message: string;
  recoveryAction: string;
  missingAgent: string | null;
  targetState: string;
}
