import type {
  MarketplaceId,
  MarketplaceTrackState,
  MarketplaceTrackStatus,
  MarketplaceTrackStatusTransition,
} from "./marketplace-track-model";

export interface UpdateMarketplaceTrackInput {
  marketplace: MarketplaceId;
  status?: MarketplaceTrackStatus;
  submissionReady?: boolean;
  warningDebtCount?: number;
  updatedAt?: Date;
}

export function updateMarketplaceTrack(
  state: MarketplaceTrackState,
  input: UpdateMarketplaceTrackInput,
): MarketplaceTrackState {
  const currentTrack = state.tracks[input.marketplace];
  const updatedAt = (input.updatedAt ?? new Date()).toISOString();

  const nextWarningDebtCount = input.warningDebtCount ?? currentTrack.warningDebtCount;
  if (nextWarningDebtCount < 0) {
    throw new Error("warningDebtCount must be greater than or equal to 0");
  }

  const nextStatus = input.status ?? currentTrack.status;
  const transitions: MarketplaceTrackStatusTransition[] =
    nextStatus !== currentTrack.status
      ? [
          ...state.transitions,
          {
            marketplace: input.marketplace,
            fromStatus: currentTrack.status,
            toStatus: nextStatus,
            transitionedAt: updatedAt,
          },
        ]
      : state.transitions;

  return {
    tracks: {
      ...state.tracks,
      [input.marketplace]: {
        ...currentTrack,
        status: nextStatus,
        submissionReady: input.submissionReady ?? currentTrack.submissionReady,
        warningDebtCount: nextWarningDebtCount,
        updatedAt,
      },
    },
    transitions,
  };
}
