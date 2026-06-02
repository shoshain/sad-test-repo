/**
 * SAD eval stub — stakeholder semi-technical case 001.
 *
 * Purpose: verify that walkthroughs/semi-technical.md references every changed
 * contract with a backward-compatibility verdict.
 */

export type EvalResult = { passed: boolean; missing: string[] };

type GroundTruth = {
  changed_contracts?: string[];
};

export function evaluateContractCoverage(
  walkthroughMarkdown: string,
  groundTruth: GroundTruth = {},
): EvalResult {
  const changedContracts = groundTruth.changed_contracts ?? [];
  const missing = changedContracts.filter((c) => !walkthroughMarkdown.includes(c));
  return { passed: missing.length === 0, missing };
}
