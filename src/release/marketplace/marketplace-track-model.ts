export const MARKETPLACE_IDS = ["cursor", "claude", "codex"] as const;

export type MarketplaceId = (typeof MARKETPLACE_IDS)[number];

export type MarketplaceTrackStatus =
  | "not-started"
  | "in-progress"
  | "on-track"
  | "at-risk"
  | "blocked"
  | "ready-to-submit"
  | "submitted";

export interface MarketplaceTrack {
  marketplace: MarketplaceId;
  status: MarketplaceTrackStatus;
  submissionReady: boolean;
  warningDebtCount: number;
  updatedAt: string;
}

export interface MarketplaceTrackStatusTransition {
  marketplace: MarketplaceId;
  fromStatus: MarketplaceTrackStatus;
  toStatus: MarketplaceTrackStatus;
  transitionedAt: string;
}

export interface MarketplaceTrackState {
  tracks: Record<MarketplaceId, MarketplaceTrack>;
  transitions: MarketplaceTrackStatusTransition[];
}

export function createMarketplaceTrackState(
  createdAt: Date = new Date(),
): MarketplaceTrackState {
  const timestamp = createdAt.toISOString();

  return {
    tracks: {
      cursor: {
        marketplace: "cursor",
        status: "not-started",
        submissionReady: false,
        warningDebtCount: 0,
        updatedAt: timestamp,
      },
      claude: {
        marketplace: "claude",
        status: "not-started",
        submissionReady: false,
        warningDebtCount: 0,
        updatedAt: timestamp,
      },
      codex: {
        marketplace: "codex",
        status: "not-started",
        submissionReady: false,
        warningDebtCount: 0,
        updatedAt: timestamp,
      },
    },
    transitions: [],
  };
}
