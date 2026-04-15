// ApprovalGate — single enforcement point for connector authorization.
// Contract: src/approval-gate.md

import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import { parse, stringify } from 'yaml';
import type { GateResult } from './types/connector';
import type { RoutingYml, ConnectorEntry } from './types/routing';

const ROUTING_PATH = path.join(os.homedir(), '.projectpal', 'routing.yml');

// Session-scoped decline flags — in-memory only, never persisted.
// Resets when the process restarts (new session).
const sessionDeclines = new Set<string>();

function loadRouting(): RoutingYml {
  if (!fs.existsSync(ROUTING_PATH)) {
    throw new Error(`routing.yml not found at ${ROUTING_PATH}. Run install to create it.`);
  }
  const raw = fs.readFileSync(ROUTING_PATH, 'utf8');
  const parsed = parse(raw) as RoutingYml;
  if (!parsed?.connectors || !Array.isArray(parsed?.routing_rules)) {
    throw new Error("routing.yml is malformed. Expected a 'routing_rules' array.");
  }
  return parsed;
}

/**
 * Check whether a connector is authorized for this session.
 *
 * approved=true             → status: "approved"
 * approved=false + declined this session → status: "declined"
 * approved=false (new session) / null / absent → status: "pending", re_fired: true
 */
export function check(connector: string): GateResult {
  const routing = loadRouting();
  const entry = routing.connectors[connector];

  if (entry?.approved === true) {
    return { status: 'approved', re_fired: false };
  }

  if (entry?.approved === false && sessionDeclines.has(connector)) {
    return { status: 'declined', re_fired: false };
  }

  // approved: false (new session re-fires once), null, or absent
  return { status: 'pending', re_fired: true };
}

/**
 * Persist an approval or decline decision to routing.yml.
 * Writes atomically: write to .tmp then rename.
 */
export function persist(connector: string, approved: boolean): void {
  const routing = loadRouting();
  const now = new Date().toISOString();

  if (!routing.connectors[connector]) {
    routing.connectors[connector] = {
      approved: null,
      approved_at: null,
      declined_at: null,
      preferred_model: null,
      override_model: null,
    } satisfies ConnectorEntry;
  }

  const entry = routing.connectors[connector];
  if (approved) {
    entry.approved = true;
    entry.approved_at = now;
    entry.declined_at = null;
    sessionDeclines.delete(connector);
  } else {
    entry.approved = false;
    entry.declined_at = now;
    entry.approved_at = null;
    sessionDeclines.add(connector); // session-scoped: prevent re-prompt this session
  }

  const tmpPath = `${ROUTING_PATH}.tmp`;
  fs.writeFileSync(tmpPath, stringify(routing), 'utf8');
  try {
    fs.renameSync(tmpPath, ROUTING_PATH);
  } catch (err) {
    try { fs.unlinkSync(tmpPath); } catch { /* ignore cleanup error */ }
    throw new Error(
      `Failed to persist routing.yml atomically: ${err instanceof Error ? err.message : String(err)}`
    );
  }
}
