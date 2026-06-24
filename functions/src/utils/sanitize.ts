const INJECTION_PATTERNS = [
  /ignore\s+(?:all\s+)?previous\s+instructions?/i,
  /new\s+instructions?/i,
  /system\s*:/i,
  /\[system\]/i,
  /you\s+are\s+now/i,
  /disregard\s+(?:all\s+)?previous/i,
  /forget\s+(?:all\s+)?previous/i,
  /override\s+(?:previous\s+)?instructions?/i,
];

const MAX_JOB_TEXT_LENGTH = 5000;

export function sanitizeJobText(text: string): string {
  const lines = text.split("\n");
  const filtered = lines.filter(
    (line) => !INJECTION_PATTERNS.some((pattern) => pattern.test(line))
  );
  const joined = filtered.join("\n");
  return joined.length > MAX_JOB_TEXT_LENGTH
    ? joined.substring(0, MAX_JOB_TEXT_LENGTH)
    : joined;
}
