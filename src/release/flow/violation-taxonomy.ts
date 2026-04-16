export const VIOLATION_IDS = [
  "missing-required-agent",
  "out-of-order-phase",
  "skipped-check-in",
  "rejected-gate-ignored",
] as const;

export type ViolationId = (typeof VIOLATION_IDS)[number];

export interface FlowViolation {
  id: ViolationId;
  expectedAgent: string;
  actualAgent: string;
  fromPhase: string;
  toPhase: string;
  message: string;
}

export const VIOLATION_MESSAGES: Record<ViolationId, string> = {
  "missing-required-agent": "A required phase agent pass is missing.",
  "out-of-order-phase": "The requested phase transition is out of order.",
  "skipped-check-in": "A mandatory user check-in was skipped.",
  "rejected-gate-ignored": "A rejected gate was ignored in transition.",
};
