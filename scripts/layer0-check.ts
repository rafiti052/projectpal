#!/usr/bin/env tsx
// Layer 0 parity checker — pre-ship quality gate for both adapters.
// Ticket: agent-platform-expansion-011
//
// Usage:
//   pnpm tsx scripts/layer0-check.ts            # uses live state + routing
//   pnpm tsx scripts/layer0-check.ts --fixture  # uses fixture files (no live API needed)
//
// Exits 0 when failures ≤ 2 (co-ship unblocked).
// Exits 1 when failures > 2 (co-ship blocked).

import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import { parse } from 'yaml';

const FIXTURE_DIR = path.join(__dirname, '..', 'tests', 'fixtures');
const LIVE_STATE_PATH = path.join(process.cwd(), '.projectpal', 'state.yml');
const LIVE_ROUTING_PATH = path.join(os.homedir(), '.projectpal', 'routing.yml');
const FIXTURE_STATE_PATH = path.join(FIXTURE_DIR, 'state.fixture.yml');
const FIXTURE_ROUTING_PATH = path.join(FIXTURE_DIR, 'routing.fixture.yml');

const useFixture =
  process.argv.includes('--fixture') ||
  !fs.existsSync(LIVE_STATE_PATH) ||
  !fs.existsSync(LIVE_ROUTING_PATH);

const statePath = useFixture ? FIXTURE_STATE_PATH : LIVE_STATE_PATH;
const routingPath = useFixture ? FIXTURE_ROUTING_PATH : LIVE_ROUTING_PATH;

const ISO_8601_RE = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$/;

type CheckResult = { adapter: string; check: string; pass: boolean; message: string };

function checkResult(adapter: string, check: string, pass: boolean, message = ''): CheckResult {
  return { adapter, check, pass, message };
}

// ── Check 1: State key schema ──────────────────────────────────────────────
function check1StateKeySchema(state: Record<string, unknown>, adapter: string): CheckResult {
  const name = 'Check 1: State key schema';
  const to = state?.['thread_orchestration'] as Record<string, unknown> | undefined;

  if (!to || typeof to !== 'object') {
    return checkResult(adapter, name, false, 'thread_orchestration is missing');
  }

  const threads = to['threads'] as Array<Record<string, unknown>> | undefined;
  if (!Array.isArray(threads) || threads.length === 0) {
    return checkResult(adapter, name, false, 'thread_orchestration.threads is empty or missing');
  }

  const thread = threads[0];
  if (!thread['primary_assistant'] || typeof thread['primary_assistant'] !== 'string') {
    return checkResult(adapter, name, false, 'threads[0].primary_assistant is missing or not a string');
  }

  // approved_execution_path_id may be null (valid) but the key must exist
  if (!('approved_execution_path_id' in thread)) {
    return checkResult(adapter, name, false, 'threads[0].approved_execution_path_id key is absent');
  }

  return checkResult(adapter, name, true, '');
}

// ── Check 2: Approval state shape ─────────────────────────────────────────
function check2ApprovalShape(routing: Record<string, unknown>, adapter: string): CheckResult {
  const name = 'Check 2: Approval state shape';
  const connectorName = adapter; // check the entry matching the adapter name
  const connectors = routing?.['connectors'] as Record<string, Record<string, unknown>> | undefined;

  if (!connectors || typeof connectors !== 'object') {
    return checkResult(adapter, name, false, 'routing.yml connectors block is missing');
  }

  const entry = connectors[connectorName];
  if (!entry) {
    return checkResult(adapter, name, false, `connectors.${connectorName} entry is absent`);
  }

  // approved: bool | null
  if (entry['approved'] !== null && typeof entry['approved'] !== 'boolean') {
    return checkResult(adapter, name, false, `connectors.${connectorName}.approved must be bool or null`);
  }

  // approved_at: ISO-8601 string or null
  if (entry['approved_at'] !== null && typeof entry['approved_at'] === 'string') {
    if (!ISO_8601_RE.test(entry['approved_at'])) {
      return checkResult(adapter, name, false, `connectors.${connectorName}.approved_at is not ISO-8601`);
    }
  } else if (entry['approved_at'] !== null) {
    return checkResult(adapter, name, false, `connectors.${connectorName}.approved_at must be ISO-8601 string or null`);
  }

  // declined_at: ISO-8601 string or null
  if (entry['declined_at'] !== null && typeof entry['declined_at'] === 'string') {
    if (!ISO_8601_RE.test(entry['declined_at'])) {
      return checkResult(adapter, name, false, `connectors.${connectorName}.declined_at is not ISO-8601`);
    }
  } else if (entry['declined_at'] !== null) {
    return checkResult(adapter, name, false, `connectors.${connectorName}.declined_at must be ISO-8601 string or null`);
  }

  return checkResult(adapter, name, true, '');
}

// ── Check 3: Thread-local write contract ──────────────────────────────────
function check3ThreadLocalWrites(state: Record<string, unknown>, adapter: string): CheckResult {
  const name = 'Check 3: Thread-local write contract';
  const to = state?.['thread_orchestration'] as Record<string, unknown> | undefined;

  if (!to) return checkResult(adapter, name, true, ''); // no thread block — vacuously passes

  const records = to['fallback_records'] as Array<Record<string, unknown>> | undefined;
  if (!records || records.length === 0) {
    return checkResult(adapter, name, true, ''); // no records — nothing to check
  }

  // Every fallback record must carry a task_id (thread-tagged)
  for (let i = 0; i < records.length; i++) {
    const rec = records[i];
    if (!rec['task_id'] || typeof rec['task_id'] !== 'string') {
      return checkResult(adapter, name, false, `fallback_records[${i}].task_id is missing — record is not thread-tagged`);
    }
  }

  return checkResult(adapter, name, true, '');
}

// ── Runner ─────────────────────────────────────────────────────────────────
function run(): void {
  console.log('Layer 0 Parity Check — agent-platform-expansion');
  console.log('='.repeat(52));
  console.log(`Mode: ${useFixture ? 'fixture' : 'live'}`);
  console.log(`State:   ${statePath}`);
  console.log(`Routing: ${routingPath}`);
  console.log('');

  let state: Record<string, unknown>;
  let routing: Record<string, unknown>;

  try {
    state = parse(fs.readFileSync(statePath, 'utf8')) as Record<string, unknown>;
  } catch (err) {
    console.error(`FATAL: cannot read state.yml — ${err instanceof Error ? err.message : String(err)}`);
    process.exit(1);
  }

  try {
    routing = parse(fs.readFileSync(routingPath, 'utf8')) as Record<string, unknown>;
  } catch (err) {
    console.error(`FATAL: cannot read routing.yml — ${err instanceof Error ? err.message : String(err)}`);
    process.exit(1);
  }

  const adapters = ['gemini', 'cursor'];
  const results: CheckResult[] = [];

  for (const adapter of adapters) {
    results.push(check1StateKeySchema(state, adapter));
    results.push(check2ApprovalShape(routing, adapter));
    results.push(check3ThreadLocalWrites(state, adapter));
  }

  // Print structured report
  for (const adapter of adapters) {
    console.log(`Adapter: ${adapter}`);
    for (const r of results.filter((x) => x.adapter === adapter)) {
      const status = r.pass ? '[PASS]' : '[FAIL]';
      const detail = r.message ? ` — ${r.message}` : '';
      console.log(`  ${status} ${r.check}${detail}`);
    }
    console.log('');
  }

  const failures = results.filter((r) => !r.pass).length;
  const threshold = 2;
  console.log(`Result: ${failures} failure${failures !== 1 ? 's' : ''} (threshold: ${threshold})`);

  if (failures > threshold) {
    console.log('Status: BLOCK — fix before co-ship');
    process.exit(1);
  } else {
    console.log('Status: PASS — co-ship unblocked');
    process.exit(0);
  }
}

run();
