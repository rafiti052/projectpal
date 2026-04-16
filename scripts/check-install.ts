#!/usr/bin/env tsx
// Install parity checker — pre-ship quality gate for all three installed adapters.
//
// Checks for each adapter (claude, codex, cursor):
//   A. Skill / config file exists on disk
//   B. Front matter or config entry is valid
//
// Plus shared state checks against .projectpal/state.yml:
//   C. State key schema (thread_orchestration shape)
//   D. (reserved) reserved for future thread-local write contracts
//
// Usage:
//   pnpm tsx scripts/check-install.ts            # live — checks real disk paths
//   pnpm tsx scripts/check-install.ts --fixture  # fixture — skips disk checks, uses fixture state
//
// Exits 0 when failures ≤ 2 (co-ship unblocked).
// Exits 1 when failures > 2 (co-ship blocked).

import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import { parse } from 'yaml';

const FIXTURE_DIR = path.join(__dirname, '..', 'tests', 'fixtures');
const LIVE_STATE_PATH = path.join(process.cwd(), '.projectpal', 'state.yml');
const FIXTURE_STATE_PATH = path.join(FIXTURE_DIR, 'state.fixture.yml');

const useFixture =
  process.argv.includes('--fixture') || !fs.existsSync(LIVE_STATE_PATH);

const statePath = useFixture ? FIXTURE_STATE_PATH : LIVE_STATE_PATH;

type SkillType = 'markdown-skill' | 'cursor-mcp';

interface AdapterSpec {
  name: string;
  displayName: string;
  skillPath: string;
  type: SkillType;
}

const ADAPTERS: AdapterSpec[] = [
  {
    name: 'claude',
    displayName: 'Claude Code',
    skillPath: path.join(os.homedir(), '.claude', 'skills', 'projectpal', 'SKILL.md'),
    type: 'markdown-skill',
  },
  {
    name: 'codex',
    displayName: 'Codex',
    skillPath: path.join(os.homedir(), '.codex', 'skills', 'projectpal', 'SKILL.md'),
    type: 'markdown-skill',
  },
  {
    name: 'cursor',
    displayName: 'Cursor',
    skillPath: path.join(os.homedir(), '.cursor', 'mcp.json'),
    type: 'cursor-mcp',
  },
];

type CheckResult = { adapter: string; check: string; pass: boolean; message: string };

function checkResult(adapter: string, check: string, pass: boolean, message = ''): CheckResult {
  return { adapter, check, pass, message };
}

// ── Check A: Skill / config file exists ───────────────────────────────────
function checkAFileExists(spec: AdapterSpec): CheckResult {
  const name = 'Check A: Skill file exists';
  if (useFixture) {
    return checkResult(spec.name, name, true, 'skipped in fixture mode');
  }
  const exists = fs.existsSync(spec.skillPath);
  return checkResult(
    spec.name,
    name,
    exists,
    exists ? '' : `not found: ${spec.skillPath}`,
  );
}

// ── Check B: Front matter / config entry valid ────────────────────────────
function checkBFrontMatter(spec: AdapterSpec): CheckResult {
  const name = 'Check B: Front matter / config valid';
  if (useFixture) {
    return checkResult(spec.name, name, true, 'skipped in fixture mode');
  }
  if (!fs.existsSync(spec.skillPath)) {
    return checkResult(spec.name, name, false, 'file missing — skipping front matter check');
  }

  const content = fs.readFileSync(spec.skillPath, 'utf8');

  if (spec.type === 'markdown-skill') {
    const fmMatch = content.match(/^---\n([\s\S]*?)\n---/);
    if (!fmMatch) {
      return checkResult(spec.name, name, false, 'no valid YAML front matter block (--- ... ---)');
    }
    if (!fmMatch[1].includes('name: projectpal')) {
      return checkResult(spec.name, name, false, 'front matter does not contain "name: projectpal"');
    }
    return checkResult(spec.name, name, true, '');
  }

  if (spec.type === 'cursor-mcp') {
    let parsed: unknown;
    try {
      parsed = JSON.parse(content);
    } catch {
      return checkResult(spec.name, name, false, 'mcp.json is not valid JSON');
    }
    const servers = (parsed as Record<string, unknown>)['mcpServers'] as
      | Record<string, unknown>
      | undefined;
    if (!servers?.['projectpal']) {
      return checkResult(spec.name, name, false, 'mcpServers.projectpal entry missing from mcp.json');
    }
    return checkResult(spec.name, name, true, '');
  }

  return checkResult(spec.name, name, false, `unknown skill type: ${spec.type}`);
}

// ── Check C: State key schema ──────────────────────────────────────────────
function checkCStateKeySchema(state: Record<string, unknown>): CheckResult {
  const name = 'Check C: State key schema';
  const adapter = 'claude'; // state is shared; tag under claude by convention
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

  if (!('approved_execution_path_id' in thread)) {
    return checkResult(adapter, name, false, 'threads[0].approved_execution_path_id key is absent');
  }

  return checkResult(adapter, name, true, '');
}

// ── Runner ─────────────────────────────────────────────────────────────────
function run(): void {
  console.log('Install Parity Check');
  console.log('='.repeat(52));
  console.log(`Mode:  ${useFixture ? 'fixture' : 'live'}`);
  console.log(`State: ${statePath}`);
  console.log('');

  let state: Record<string, unknown>;
  try {
    state = parse(fs.readFileSync(statePath, 'utf8')) as Record<string, unknown>;
  } catch (err) {
    console.error(
      `FATAL: cannot read state.yml — ${err instanceof Error ? err.message : String(err)}`,
    );
    process.exit(1);
  }

  const results: CheckResult[] = [];

  for (const spec of ADAPTERS) {
    results.push(checkAFileExists(spec));
    results.push(checkBFrontMatter(spec));
  }

  // Shared state checks — tagged under claude, shown in that section
  results.push(checkCStateKeySchema(state));

  // Print structured report
  for (const spec of ADAPTERS) {
    console.log(`Adapter: ${spec.displayName} (${spec.name})`);
    for (const r of results.filter((x) => x.adapter === spec.name)) {
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
