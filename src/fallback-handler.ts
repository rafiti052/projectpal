// FallbackHandler — evaluates connector failures, determines materiality,
// writes fallback records to state.yml, and returns the disclosure decision.
// Contract: src/fallback-handler.md
// Ticket: agent-platform-expansion-008

import * as fs from 'fs';
import * as path from 'path';
import { parseDocument } from 'yaml';
import type { NormalizedFailure, FallbackEvaluation } from './types/connector';
import * as router from './connector-router';

let _statePath = path.join(process.cwd(), '.projectpal', 'state.yml');

/** For testing only — override the default state.yml path. */
export function _setStatePath(p: string): void {
  _statePath = p;
}

type FallbackType = 'retry_same_path' | 'equivalent_substitution' | 'path_switch_request' | 'none';
type OutcomeType = 'succeeded' | 'failed' | 'awaiting_approval' | 'blocked';

interface FallbackRecord {
  fallback_id: string;
  task_id: string;
  attempt_number: number;
  fallback_type: FallbackType;
  from_execution_path_id: string | null;
  to_execution_path_id: string | null;
  changed_fields: string[];
  approval_required: boolean;
  disclosed_in_next_summary: boolean;
  outcome: OutcomeType;
}

function generateFallbackId(): string {
  return `fb-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
}

/**
 * Determine the persistence-level fallback_type from attempt number.
 * v1 policy: first attempt → retry_same_path; subsequent → path_switch_request.
 */
function resolveFallbackType(attemptNumber: number): FallbackType {
  return attemptNumber <= 1 ? 'retry_same_path' : 'path_switch_request';
}

/**
 * Append a fallback record to .projectpal/state.yml under
 * thread_orchestration.fallback_records. Comment-preserving via yaml Document API.
 */
function appendRecord(record: FallbackRecord): void {
  if (!fs.existsSync(_statePath)) return; // state.yml missing — skip persistence silently

  const raw = fs.readFileSync(_statePath, 'utf8');
  const doc = parseDocument(raw);

  const existingRecords = doc.getIn(['thread_orchestration', 'fallback_records']);
  if (!existingRecords) {
    doc.setIn(['thread_orchestration', 'fallback_records'], doc.createNode([record]));
  } else {
    // existingRecords is a YAMLSeq — add() appends without overwriting
    (existingRecords as import('yaml').YAMLSeq).add(doc.createNode(record));
  }

  fs.writeFileSync(_statePath, String(doc), 'utf8');
}

/**
 * Evaluate a connector failure and record it.
 *
 * material_impact = true when the failed connector is the designated connector
 * for the current phase + task_type routing rule.
 */
export function evaluate(task: NormalizedFailure & { phase: number; task_type: string }, failure: NormalizedFailure): FallbackEvaluation {
  let material_impact = false;

  try {
    const selection = router.resolve(task.phase, task.task_type);
    material_impact = selection !== null && selection.connector === failure.connector;
  } catch {
    // Router unavailable or routing.yml missing — treat as non-material
    material_impact = false;
  }

  const fallback_type = material_impact ? 'disclosed' : 'silent';
  const approval_required = material_impact;
  const disclosure_message = material_impact
    ? 'The refinement step ran on the primary assistant because the routed connector was unavailable.'
    : null;

  const record: FallbackRecord = {
    fallback_id: generateFallbackId(),
    task_id: failure.task_id,
    attempt_number: failure.attempt_number,
    fallback_type: resolveFallbackType(failure.attempt_number),
    from_execution_path_id: failure.from_execution_path_id,
    to_execution_path_id: null,
    changed_fields: [],
    approval_required,
    disclosed_in_next_summary: material_impact,
    outcome: approval_required ? 'awaiting_approval' : 'failed',
  };

  appendRecord(record);

  return { fallback_type, approval_required, material_impact, disclosure_message };
}
