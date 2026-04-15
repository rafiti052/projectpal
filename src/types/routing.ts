// TypeScript types for ~/.projectpal/routing.yml
// Schema: src/schemas/routing-yml.schema.json

export interface ConnectorEntry {
  approved: boolean | null;
  approved_at: string | null;
  declined_at: string | null;
  preferred_model: string | null;
  override_model: string | null;
}

export interface RoutingRule {
  phase: number;
  task_type: string;
  connector: string;
  model: string;
  fallback: string;
}

export interface RoutingYml {
  version: 1;
  connectors: Record<string, ConnectorEntry>;
  routing_rules: RoutingRule[];
}
