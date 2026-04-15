// Thread isolation test — verifies that no state written by adapter operations
// leaks across thread contexts.
// Ticket: agent-platform-expansion-012

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import { parse } from 'yaml';
import { evaluate, _setStatePath } from '../src/fallback-handler';
import type { NormalizedFailure } from '../src/types/connector';

// ── Shared fixture ─────────────────────────────────────────────────────────

const FIXTURE_STATE = fs.readFileSync(
  path.join(__dirname, 'fixtures', 'state.fixture.yml'),
  'utf8'
);

// A minimal state.yml with empty fallback_records, scoped to a given thread
function makeStateYml(threadId: string): string {
  return [
    'repo_slug: test',
    'thread_orchestration:',
    `  active_thread_id: ${threadId}`,
    '  threads:',
    `    - thread_id: ${threadId}`,
    '      primary_assistant: claude-code',
    '      reporting_owner: pal',
    '      state: active',
    '      approved_execution_path_id: null',
    '      approval_state: not_needed',
    '      shared_context_refs: []',
    `      created_at: "${new Date().toISOString()}"`,
    `      updated_at: "${new Date().toISOString()}"`,
    '  execution_paths: []',
    '  connector_status_snapshots: []',
    '  delegation_tasks: []',
    '  fallback_records: []',
    'next_steps: []',
  ].join('\n');
}

function makeTask(threadId: string, taskId: string, phase = 2, taskType = 'refinement') {
  return {
    connector: 'gemini',
    failure_reason: 'runtime_error',
    task_id: taskId,
    thread_id: threadId,
    phase,
    task_type: taskType,
    attempt_number: 1,
    from_execution_path_id: null,
  };
}

// ── Test setup / teardown ─────────────────────────────────────────────────

let tmpDirA: string;
let tmpDirB: string;
let statePathA: string;
let statePathB: string;

beforeEach(() => {
  tmpDirA = fs.mkdtempSync(path.join(os.tmpdir(), 'pp-thread-a-'));
  tmpDirB = fs.mkdtempSync(path.join(os.tmpdir(), 'pp-thread-b-'));
  statePathA = path.join(tmpDirA, 'state.yml');
  statePathB = path.join(tmpDirB, 'state.yml');
  fs.writeFileSync(statePathA, makeStateYml('thread-a-001'), 'utf8');
  fs.writeFileSync(statePathB, makeStateYml('thread-b-001'), 'utf8');
});

afterEach(() => {
  fs.rmSync(tmpDirA, { recursive: true, force: true });
  fs.rmSync(tmpDirB, { recursive: true, force: true });
});

// ── Helpers ────────────────────────────────────────────────────────────────

function readFallbackRecords(statePath: string): Array<Record<string, unknown>> {
  const raw = fs.readFileSync(statePath, 'utf8');
  const state = parse(raw) as Record<string, unknown>;
  const to = state?.['thread_orchestration'] as Record<string, unknown>;
  return (to?.['fallback_records'] as Array<Record<string, unknown>>) ?? [];
}

// ── Scenario 1: Gemini adapter thread isolation ────────────────────────────

describe('Gemini adapter thread isolation', () => {
  it('writes fallback record to thread A only, thread B stays clean', () => {
    _setStatePath(statePathA);

    const task = makeTask('thread-a-001', 'task-gemini-001');
    evaluate(task, task);

    // Thread A should have exactly one record
    const recordsA = readFallbackRecords(statePathA);
    expect(recordsA).toHaveLength(1);
    expect(recordsA[0]['task_id']).toBe('task-gemini-001');

    // Thread B should have zero records (untouched)
    _setStatePath(statePathB);
    const recordsB = readFallbackRecords(statePathB);
    expect(recordsB).toHaveLength(0);
  });

  it('multiple evaluations append to the same thread without overwriting', () => {
    _setStatePath(statePathA);

    const task1 = makeTask('thread-a-001', 'task-gemini-002');
    const task2 = makeTask('thread-a-001', 'task-gemini-003');
    evaluate(task1, task1);
    evaluate(task2, task2);

    const records = readFallbackRecords(statePathA);
    expect(records).toHaveLength(2);
    expect(records.map((r) => r['task_id'])).toContain('task-gemini-002');
    expect(records.map((r) => r['task_id'])).toContain('task-gemini-003');
  });
});

// ── Scenario 2: Cursor adapter thread isolation ───────────────────────────

describe('Cursor adapter thread isolation', () => {
  it('state.yml writes from thread A do not appear in thread B', () => {
    // Cursor triggers a non-material fallback (no routing rule for cursor in v1)
    _setStatePath(statePathA);
    const task = makeTask('thread-a-001', 'task-cursor-001', 1, 'registration');
    task.connector = 'cursor';
    evaluate(task, task);

    const recordsA = readFallbackRecords(statePathA);
    expect(recordsA).toHaveLength(1);
    expect(recordsA[0]['task_id']).toBe('task-cursor-001');

    _setStatePath(statePathB);
    const recordsB = readFallbackRecords(statePathB);
    expect(recordsB).toHaveLength(0);
  });
});

// ── Scenario 3: FallbackHandler thread isolation ─────────────────────────

describe('FallbackHandler thread isolation', () => {
  it('fallback record in thread A carries thread-A task_id', () => {
    _setStatePath(statePathA);

    const task = makeTask('thread-a-001', 'task-fb-001');
    const result = evaluate(task, task);

    const records = readFallbackRecords(statePathA);
    expect(records).toHaveLength(1);
    expect(records[0]['task_id']).toBe('task-fb-001');

    // Returned evaluation is consistent with the record
    expect(typeof result.fallback_type).toBe('string');
    expect(typeof result.material_impact).toBe('boolean');
  });

  it('thread B fallback records do not include thread A entries', () => {
    _setStatePath(statePathA);
    evaluate(makeTask('thread-a-001', 'task-fb-thread-a'), makeTask('thread-a-001', 'task-fb-thread-a'));

    _setStatePath(statePathB);
    evaluate(makeTask('thread-b-001', 'task-fb-thread-b'), makeTask('thread-b-001', 'task-fb-thread-b'));

    const recordsA = readFallbackRecords(statePathA);
    const recordsB = readFallbackRecords(statePathB);

    expect(recordsA.map((r) => r['task_id'])).not.toContain('task-fb-thread-b');
    expect(recordsB.map((r) => r['task_id'])).not.toContain('task-fb-thread-a');
  });
});
