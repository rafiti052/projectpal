// Orchestration entry: routing → approval gate → adapter.invoke.
// Experimental until a ProjectPal CLI exists — see docs/north-star.md §14. Optional
// routed delegation (e.g. Gemini) is not required for core Pal behavior in assistants today.

import * as router from './connector-router';
import * as gate from './approval-gate';
import type { DelegationTask, DelegationResult } from './types/connector';
import { registerDefaultAdapters } from './register-default-adapters';

export type RoutedInvokeOutcome =
  | { kind: 'no_rule' }
  | { kind: 'pending_approval'; connector: string }
  | { kind: 'declined'; connector: string }
  | { kind: 'invoked'; result: DelegationResult; connector: string; model: string };

/**
 * Resolve routing for the task's phase + task_type, run ApprovalGate, then invoke
 * the selected adapter when approved.
 */
export async function invokeRoutedDelegation(task: DelegationTask): Promise<RoutedInvokeOutcome> {
  registerDefaultAdapters();

  const selection = router.resolve(task.phase, task.task_type);
  if (!selection) {
    return { kind: 'no_rule' };
  }

  const gateResult = gate.check(selection.connector);
  if (gateResult.status === 'pending') {
    return { kind: 'pending_approval', connector: selection.connector };
  }
  if (gateResult.status === 'declined') {
    return { kind: 'declined', connector: selection.connector };
  }

  const result = await selection.adapter.invoke(task, selection.model);
  return { kind: 'invoked', result, connector: selection.connector, model: selection.model };
}
