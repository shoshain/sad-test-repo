/**
 * SAD eval stub — stakeholder technical case 001.
 *
 * Purpose: deterministic check that walkthroughs/technical.md contains a
 * reviewer rollup table referencing required reviewer rows.
 */

export type EvalResult = { passed: boolean; missingHeaders: string[] };

type GroundTruth = {
  required_headers?: string[];
};

export function evaluateReviewerTable(
  walkthroughMarkdown: string,
  groundTruth: GroundTruth = {},
): EvalResult {
  const requiredHeaders = groundTruth.required_headers ?? [];
  const missingHeaders = requiredHeaders.filter(
    (h) => !walkthroughMarkdown.toLowerCase().includes(h.toLowerCase()),
  );
  return { passed: missingHeaders.length === 0, missingHeaders };
}
