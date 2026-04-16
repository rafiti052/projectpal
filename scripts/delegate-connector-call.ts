#!/usr/bin/env npx tsx
/**
 * Run a single routed connector call (routing.yml phase + task_type → adapter).
 * Used when the Pal delegates Brief drafting to Gemini per routing rule.
 *
 * Usage:
 *   pnpm exec tsx scripts/delegate-connector-call.ts <phase> <task_type> <task_id> <thread_id> < summary.txt
 *   cat summary.txt | pnpm exec tsx scripts/delegate-connector-call.ts 1 brief tid-1 th-1
 *
 * If ApprovalGate returns pending, prompts once on stderr (y/N); persists approval on y.
 */

import * as readline from 'readline';
import * as gate from '../src/approval-gate';
import type { DelegationTask } from '../src/types/connector';
import { invokeRoutedDelegation } from '../src/connector-orchestration';

function promptApprove(connector: string): Promise<boolean> {
  if (!process.stdin.isTTY) {
    console.error(
      `[projectpal] Connector "${connector}" is not approved. Set routing.yml approved: true or run in a TTY to answer the prompt.`
    );
    return Promise.resolve(false);
  }
  const rl = readline.createInterface({ input: process.stdin, output: process.stderr });
  return new Promise((resolve) => {
    rl.question(
      `[projectpal] Allow connector "${connector}" for this machine (writes ~/.projectpal/routing.yml)? [y/N] `,
      (answer) => {
        rl.close();
        resolve(/^y(es)?$/i.test(answer.trim()));
      }
    );
  });
}

async function main(): Promise<void> {
  const argv = process.argv.slice(2);
  if (argv.length < 4) {
    console.error(
      'usage: pnpm exec tsx scripts/delegate-connector-call.ts <phase> <task_type> <task_id> <thread_id> [acceptance_summary]\n' +
        '  Body: remaining argv as one string, or pipe stdin for acceptance_criteria_summary when argv[4] omitted.'
    );
    process.exit(1);
  }

  const phase = Number(argv[0]);
  const task_type = argv[1]!;
  const task_id = argv[2]!;
  const thread_id = argv[3]!;
  let acceptance_criteria_summary =
    argv.slice(4).join(' ').trim() ||
    (await new Promise<string>((resolve, reject) => {
      let data = '';
      process.stdin.setEncoding('utf8');
      process.stdin.on('data', (chunk) => {
        data += chunk;
      });
      process.stdin.on('end', () => resolve(data.trim()));
      process.stdin.on('error', reject);
    }));

  if (!acceptance_criteria_summary) {
    console.error('No acceptance_criteria_summary: pass as argv tail or stdin.');
    process.exit(1);
  }

  if (!Number.isInteger(phase)) {
    console.error('phase must be an integer');
    process.exit(1);
  }

  const task: DelegationTask = {
    task_id,
    thread_id,
    task_type,
    acceptance_criteria_summary,
    execution_path_id: 'delegate-connector-call',
    phase,
  };

  let outcome = await invokeRoutedDelegation(task);

  if (outcome.kind === 'pending_approval') {
    const ok = await promptApprove(outcome.connector);
    if (ok) {
      gate.persist(outcome.connector, true);
      outcome = await invokeRoutedDelegation(task);
    } else {
      gate.persist(outcome.connector, false);
      console.log(JSON.stringify({ kind: 'declined', connector: outcome.connector }, null, 2));
      process.exit(2);
    }
  }

  if (outcome.kind === 'no_rule') {
    console.log(
      JSON.stringify({ kind: 'no_rule', message: 'No routing rule matched — use primary assistant.' }, null, 2)
    );
    process.exit(0);
  }

  if (outcome.kind === 'declined') {
    console.log(JSON.stringify({ kind: 'declined', connector: outcome.connector }, null, 2));
    process.exit(2);
  }

  console.log(
    JSON.stringify(
      {
        kind: 'invoked',
        connector: outcome.connector,
        model: outcome.model,
        result: outcome.result,
      },
      null,
      2
    )
  );
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
