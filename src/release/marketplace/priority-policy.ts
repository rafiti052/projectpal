import type { MarketplaceId } from "./marketplace-track-model";

export interface MarketplacePriority {
  marketplace: MarketplaceId;
  rank: number;
  checkpointCadence: "daily" | "weekly";
}

export const MARKETPLACE_PRIORITY_POLICY: readonly MarketplacePriority[] = [
  {
    marketplace: "cursor",
    rank: 1,
    checkpointCadence: "daily",
  },
  {
    marketplace: "claude",
    rank: 2,
    checkpointCadence: "weekly",
  },
  {
    marketplace: "codex",
    rank: 3,
    checkpointCadence: "weekly",
  },
] as const;

export function getMarketplacePriority(marketplace: MarketplaceId): MarketplacePriority {
  const policy = MARKETPLACE_PRIORITY_POLICY.find(
    (priority) => priority.marketplace === marketplace,
  );

  if (!policy) {
    throw new Error(`No marketplace priority configured for ${marketplace}`);
  }

  return policy;
}
