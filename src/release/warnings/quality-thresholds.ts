export const WARNING_CLARITY_MAX_WORDS = 60;
export const WARNING_CLARITY_MAX_SENTENCES = 2;
export const WARNING_TIMING_MAX_DELTA_MS = 2_000;

export const WARNING_PLACEHOLDER_PATTERN = /\b(todo|tbd|placeholder|xxx)\b/i;
export const WARNING_GENERIC_FIX_PATTERN = /\bfix (this|it)\b/i;

export const WARNING_IMPERATIVE_START_PATTERN =
  /^(run|return|complete|resolve|retry|review|use|update|switch|capture|rerun)\b/i;
