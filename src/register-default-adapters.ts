// Register built-in connector adapters. Safe to call multiple times.

import { register } from './adapter-registry';
import { GeminiAdapter } from './adapters/gemini-adapter';

let registered = false;

/** Idempotent — registers default adapters so ConnectorRouter.resolve can succeed. */
export function registerDefaultAdapters(): void {
  if (registered) return;
  register('gemini', new GeminiAdapter());
  registered = true;
}
