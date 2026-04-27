import type { FlowViolation, ViolationId } from "./violation-taxonomy";
import { VIOLATION_MESSAGES } from "./violation-taxonomy";

export type PhaseId =
  | "discovery"
  | "brief"
  | "refinement"
  | "solution"
  | "planning"
  | "technical-details"
  | "tickets"
  | "implementation"
  | "wrap-up";

export type AgentId =
  | "pal"
  | "strategist"
  | "architect"
  | "manager"
  | "tech-lead"
  | "scrum-master"
  | "designer"
  | "engineer";

export interface PhaseAgentRule {
  fromPhase: PhaseId;
  toPhase: PhaseId;
  requiredAgent: AgentId;
  active: boolean;
}

export interface ValidationContext {
  fromPhase: PhaseId;
  toPhase: PhaseId;
  actingAgent: AgentId;
}

export interface ValidationResult {
  allowed: boolean;
  violation?: FlowViolation;
}

export const DEFAULT_PHASE_AGENT_RULES: PhaseAgentRule[] = [
  { fromPhase: "discovery", toPhase: "brief", requiredAgent: "strategist", active: true },
  { fromPhase: "brief", toPhase: "refinement", requiredAgent: "architect", active: true },
  { fromPhase: "brief", toPhase: "solution", requiredAgent: "pal", active: true },
  { fromPhase: "refinement", toPhase: "solution", requiredAgent: "pal", active: true },
  { fromPhase: "solution", toPhase: "planning", requiredAgent: "pal", active: true },
  { fromPhase: "solution", toPhase: "tickets", requiredAgent: "scrum-master", active: true },
  { fromPhase: "planning", toPhase: "technical-details", requiredAgent: "tech-lead", active: true },
  { fromPhase: "technical-details", toPhase: "tickets", requiredAgent: "scrum-master", active: true },
  { fromPhase: "tickets", toPhase: "implementation", requiredAgent: "engineer", active: true },
  { fromPhase: "implementation", toPhase: "wrap-up", requiredAgent: "pal", active: true },
];

function toViolation(
  id: ViolationId,
  expectedAgent: string,
  actualAgent: string,
  fromPhase: PhaseId,
  toPhase: PhaseId,
): FlowViolation {
  return {
    id,
    expectedAgent,
    actualAgent,
    fromPhase,
    toPhase,
    message: VIOLATION_MESSAGES[id],
  };
}

export function validatePhaseAgentTransition(
  context: ValidationContext,
  rules: PhaseAgentRule[] = DEFAULT_PHASE_AGENT_RULES,
): ValidationResult {
  const rule = rules.find(
    (candidate) =>
      candidate.active &&
      candidate.fromPhase === context.fromPhase &&
      candidate.toPhase === context.toPhase,
  );

  if (!rule) {
    return {
      allowed: false,
      violation: toViolation(
        "out-of-order-phase",
        "n/a",
        context.actingAgent,
        context.fromPhase,
        context.toPhase,
      ),
    };
  }

  if (rule.requiredAgent !== context.actingAgent) {
    return {
      allowed: false,
      violation: toViolation(
        "missing-required-agent",
        rule.requiredAgent,
        context.actingAgent,
        context.fromPhase,
        context.toPhase,
      ),
    };
  }

  return { allowed: true };
}
