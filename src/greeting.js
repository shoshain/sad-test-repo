// Toy feature: build a personal greeting for a signed-in user.
// SAD will spec, plan, walkthrough, implement, review, and reconcile around this file.

export const GREETING_MIN = 1;
export const GREETING_MAX = 140;

/**
 * Build a deterministic greeting for a user.
 *
 * @param {string} name - 1..140 plain-text characters; no newlines, no markdown.
 * @returns {string}
 * @throws {Error} when name is empty, too long, or contains newlines.
 */
export function buildGreeting(name) {
  if (typeof name !== "string") {
    throw new TypeError("name must be a string");
  }
  if (name.length < GREETING_MIN || name.length > GREETING_MAX) {
    throw new RangeError(`name must be ${GREETING_MIN}..${GREETING_MAX} characters`);
  }
  if (name.includes("\n") || name.includes("\r")) {
    throw new Error("name must be a single line");
  }
  return `Hello, ${name}.`;
}

// Allow `node src/greeting.js Sam` from the CLI for a quick smoke test.
if (import.meta.url === `file://${process.argv[1]}`) {
  const name = process.argv[2] ?? "world";
  try {
    console.log(buildGreeting(name));
  } catch (err) {
    console.error(err.message);
    process.exit(1);
  }
}
