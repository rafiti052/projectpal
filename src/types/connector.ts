// Shared connector shapes.
// Source of truth: src/adapters/connector-adapter.md

export type ResultState = 'success' | 'failure' | 'timeout' | 'skipped';

export type FailureReason =
  | 'auth'
  | 'quota'
  | 'timeout'
  | 'runtime_error'
  | 'unknown'
  | 'cursor adapter is not routable';

export interface DelegationTask {
  task_id: string;
  thread_id: string;
  task_type: string;
  acceptance_criteria_summary: string;
  execution_path_id: string;
  phase: number;
}

export interface DelegationResult {
  result_state: ResultState;
  output: string | null;
  failure_reason: FailureReason | null;
  elapsed_seconds: number;
}

export interface ConnectorStatusSnapshot {
  connector: string;
  reachable: boolean;
  last_checked_at: string | null;
  last_failure_at: string | null;
}

export interface ConnectorAdapter {
  invoke(task: DelegationTask, model_override: string | null): Promise<DelegationResult>;
  check_status(): Promise<ConnectorStatusSnapshot>;
  heartbeat_hook(elapsed_seconds: number): void;
}

export interface AdapterSelection {
  connector: string;
  adapter: ConnectorAdapter;
  model: string;
  fallback: string;
}

export interface GateResult {
  status: 'approved' | 'declined' | 'pending';
  re_fired: boolean;
}

export interface NormalizedFailure {
  connector: string;
  failure_reason: string;
  task_id: string;
  thread_id: string;
  attempt_number: number;
  from_execution_path_id: string | null;
}

export interface FallbackEvaluation {
  fallback_type: 'silent' | 'disclosed' | 'blocked';
  approval_required: boolean;
  material_impact: boolean;
  disclosure_message: string | null;
}
