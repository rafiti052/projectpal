// ConnectorRouter — reads routing_rules from routing.yml and returns the adapter
// selection for a given phase + task type. Read-only against all persistent state.
// Contract: src/connector-router.md

import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import { parse } from 'yaml';
import type { AdapterSelection } from './types/connector';
import type { RoutingYml } from './types/routing';
import * as registry from './adapter-registry';

const ROUTING_PATH = path.join(os.homedir(), '.projectpal', 'routing.yml');

function loadRoutingRules(): RoutingYml {
  if (!fs.existsSync(ROUTING_PATH)) {
    throw new Error(
      `routing.yml not found at ${ROUTING_PATH}. Run install to create it.`
    );
  }
  const raw = fs.readFileSync(ROUTING_PATH, 'utf8');
  const parsed = parse(raw) as RoutingYml;
  if (!parsed?.routing_rules || !Array.isArray(parsed.routing_rules)) {
    throw new Error("routing.yml is malformed. Expected a 'routing_rules' array.");
  }
  return parsed;
}

/**
 * Resolve the adapter selection for a given phase and task type.
 *
 * Returns null when no rule matches (caller should use primary assistant).
 * Throws when a matched connector is not registered in the adapter registry.
 * Reads routing.yml fresh on every call — rules may change without restart.
 */
export function resolve(phase: number, task_type: string): AdapterSelection | null {
  const routing = loadRoutingRules();

  // First-match wins
  for (const rule of routing.routing_rules) {
    if (rule.phase === phase && rule.task_type === task_type) {
      const adapter = registry.get(rule.connector);
      if (!adapter) {
        throw new Error(
          `Connector '${rule.connector}' matched a routing rule but is not registered. ` +
          `Check routing.yml and ensure the adapter is installed.`
        );
      }
      return {
        connector: rule.connector,
        adapter,
        model: rule.model,
        fallback: rule.fallback,
      };
    }
  }

  return null; // No matching rule — caller uses primary assistant
}
