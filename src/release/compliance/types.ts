export interface MitLicenseParityContext {
  rootLicenseSpdx: string | null | undefined;
  manifestLicenseSpdx: string | null | undefined;
}

export interface MitLicenseParityResult {
  rootLicenseSpdx: string | null;
  manifestLicenseSpdx: string | null;
  rootIsMit: boolean;
  manifestIsMit: boolean;
  passed: boolean;
}
