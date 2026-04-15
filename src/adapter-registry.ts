// Connector adapter registry.
// Callers register adapters at startup before calling ConnectorRouter.resolve.

import type { ConnectorAdapter } from './types/connector';

const registry = new Map<string, ConnectorAdapter>();

export function register(name: string, adapter: ConnectorAdapter): void {
  registry.set(name, adapter);
}

export function get(name: string): ConnectorAdapter | undefined {
  return registry.get(name);
}

export function isRegistered(name: string): boolean {
  return registry.has(name);
}
