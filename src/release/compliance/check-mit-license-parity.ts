import type { MitLicenseParityContext, MitLicenseParityResult } from "./types";

const MIT_SPDX = "MIT";

function normalizeSpdx(value: string | null | undefined): string | null {
  if (typeof value !== "string") {
    return null;
  }

  const normalized = value.trim();
  return normalized.length > 0 ? normalized : null;
}

function isMitSpdx(value: string | null): boolean {
  return value?.toUpperCase() === MIT_SPDX;
}

export function checkMitLicenseParity(context: MitLicenseParityContext): MitLicenseParityResult {
  const rootLicenseSpdx = normalizeSpdx(context.rootLicenseSpdx);
  const manifestLicenseSpdx = normalizeSpdx(context.manifestLicenseSpdx);

  const rootIsMit = isMitSpdx(rootLicenseSpdx);
  const manifestIsMit = isMitSpdx(manifestLicenseSpdx);

  return {
    rootLicenseSpdx,
    manifestLicenseSpdx,
    rootIsMit,
    manifestIsMit,
    passed: rootIsMit && manifestIsMit,
  };
}
