import type { ViolationId } from "../flow/violation-taxonomy";
import type { WarningAuditEvent } from "./warning-event-schema";

function cloneEvent(event: WarningAuditEvent): WarningAuditEvent {
  return {
    ...event,
    qualityChecks: {
      messageQuality: { ...event.qualityChecks.messageQuality },
      deliveryQuality: { ...event.qualityChecks.deliveryQuality },
    },
  };
}

export class WarningAuditRepository {
  private readonly records: WarningAuditEvent[] = [];

  save(event: WarningAuditEvent): WarningAuditEvent {
    const stored = cloneEvent(event);
    this.records.push(stored);
    return cloneEvent(stored);
  }

  getAll(): WarningAuditEvent[] {
    return this.records.map((record) => cloneEvent(record));
  }

  getByViolation(violationId: ViolationId): WarningAuditEvent[] {
    return this.records
      .filter((record) => record.violationId === violationId)
      .map((record) => cloneEvent(record));
  }
}
