// GeminiAdapter — delegated external-model calls via Gemini API.
// Contract: src/adapters/gemini.md
// Ticket: agent-platform-expansion-006

import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import { parse } from 'yaml';
import type {
  ConnectorAdapter,
  DelegationTask,
  DelegationResult,
  ConnectorStatusSnapshot,
  FailureReason,
} from '../types/connector';
import type { RoutingYml } from '../types/routing';

const ROUTING_PATH = path.join(os.homedir(), '.projectpal', 'routing.yml');
const GEMINI_API_BASE = 'https://generativelanguage.googleapis.com/v1beta';
const HEARTBEAT_INTERVAL_MS = 60_000;

// Internal model name → Gemini API model name
const MODEL_MAP: Record<string, string> = {
  'gemini-fast': 'gemini-2.0-flash',
  'gemini': 'gemini-1.5-pro',
};

function resolveApiModel(name: string): string {
  return MODEL_MAP[name] ?? name;
}

function loadRoutingConnector(): { preferred_model: string | null; override_model: string | null } | null {
  try {
    if (!fs.existsSync(ROUTING_PATH)) return null;
    const parsed = parse(fs.readFileSync(ROUTING_PATH, 'utf8')) as RoutingYml;
    return parsed?.connectors?.['gemini'] ?? null;
  } catch {
    return null;
  }
}

export class GeminiAdapter implements ConnectorAdapter {
  // In-memory failure state — never written directly by this adapter
  private lastFailureAt: string | null = null;

  /**
   * Resolve the model in priority order:
   * 1. model_override (caller-supplied)
   * 2. connectors.gemini.override_model from routing.yml
   * 3. connectors.gemini.preferred_model from routing.yml
   * 4. hard fallback: "gemini-fast"
   */
  private resolveModel(model_override: string | null): string {
    if (model_override) return model_override;
    const connector = loadRoutingConnector();
    if (connector?.override_model) return connector.override_model;
    if (connector?.preferred_model) return connector.preferred_model;
    return 'gemini-fast';
  }

  /**
   * Invoke the Gemini API with the task payload.
   * Emits a heartbeat every ~60 seconds while awaiting the response.
   * Falls back to a pre-call signal if the runtime cannot run the interval
   * (documented path: "pre-call fallback: loop blocked").
   */
  async invoke(task: DelegationTask, model_override: string | null): Promise<DelegationResult> {
    const apiKey = process.env['GEMINI_API_KEY'];
    if (!apiKey) {
      return {
        result_state: 'failure',
        output: null,
        failure_reason: 'auth',
        elapsed_seconds: 0,
      };
    }

    const modelName = this.resolveModel(model_override);
    const apiModel = resolveApiModel(modelName);
    const startMs = Date.now();

    // Heartbeat setup — setInterval works in Node.js (non-blocking env)
    let heartbeatTimer: ReturnType<typeof setInterval> | null = null;
    const startHeartbeat = (): boolean => {
      try {
        heartbeatTimer = setInterval(() => {
          const elapsed = Math.floor((Date.now() - startMs) / 1000);
          this.heartbeat_hook(elapsed);
        }, HEARTBEAT_INTERVAL_MS);
        return true;
      } catch {
        return false; // pre-call fallback: loop blocked
      }
    };

    const heartbeatStarted = startHeartbeat();
    if (!heartbeatStarted) {
      // pre-call fallback: loop blocked — emit once before the request
      this.heartbeat_hook(0);
    }

    try {
      const url = `${GEMINI_API_BASE}/models/${apiModel}:generateContent?key=${apiKey}`;
      const body = JSON.stringify({
        contents: [{ parts: [{ text: task.acceptance_criteria_summary }] }],
      });

      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body,
      });

      const elapsed = Math.floor((Date.now() - startMs) / 1000);

      if (response.status === 401 || response.status === 403) {
        this.lastFailureAt = new Date().toISOString();
        return { result_state: 'failure', output: null, failure_reason: 'auth', elapsed_seconds: elapsed };
      }

      if (response.status === 429) {
        this.lastFailureAt = new Date().toISOString();
        return { result_state: 'failure', output: null, failure_reason: 'quota', elapsed_seconds: elapsed };
      }

      if (!response.ok) {
        this.lastFailureAt = new Date().toISOString();
        return { result_state: 'failure', output: null, failure_reason: 'runtime_error', elapsed_seconds: elapsed };
      }

      const data = await response.json() as {
        candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
      };

      const text = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? null;
      if (!text) {
        this.lastFailureAt = new Date().toISOString();
        return { result_state: 'failure', output: null, failure_reason: 'unknown', elapsed_seconds: elapsed };
      }

      return { result_state: 'success', output: text, failure_reason: null, elapsed_seconds: elapsed };

    } catch (err) {
      const elapsed = Math.floor((Date.now() - startMs) / 1000);
      this.lastFailureAt = new Date().toISOString();
      const isTimeout = err instanceof Error && err.name === 'TimeoutError';
      const reason: FailureReason = isTimeout ? 'timeout' : 'runtime_error';
      return { result_state: isTimeout ? 'timeout' : 'failure', output: null, failure_reason: reason, elapsed_seconds: elapsed };
    } finally {
      if (heartbeatTimer) clearInterval(heartbeatTimer);
    }
  }

  /**
   * Lightweight status probe via the models list endpoint.
   * No state mutations — FallbackHandler owns persistence.
   */
  async check_status(): Promise<ConnectorStatusSnapshot> {
    const now = new Date().toISOString();
    const apiKey = process.env['GEMINI_API_KEY'];

    if (!apiKey) {
      this.lastFailureAt = now;
      return {
        connector: 'gemini',
        reachable: false,
        last_checked_at: now,
        last_failure_at: this.lastFailureAt,
      };
    }

    try {
      const url = `${GEMINI_API_BASE}/models?key=${apiKey}&pageSize=1`;
      const response = await fetch(url);

      if (!response.ok) {
        this.lastFailureAt = now;
        return { connector: 'gemini', reachable: false, last_checked_at: now, last_failure_at: this.lastFailureAt };
      }

      return { connector: 'gemini', reachable: true, last_checked_at: now, last_failure_at: this.lastFailureAt };
    } catch {
      this.lastFailureAt = now;
      return { connector: 'gemini', reachable: false, last_checked_at: now, last_failure_at: this.lastFailureAt };
    }
  }

  /**
   * Called by the heartbeat polling loop approximately every 60 seconds.
   * Default implementation logs elapsed time.
   */
  heartbeat_hook(elapsed_seconds: number): void {
    console.log(`[gemini] heartbeat — ${elapsed_seconds}s elapsed`);
  }
}
