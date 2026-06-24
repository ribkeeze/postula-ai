export function getTodayKey(): string {
  const now = new Date();
  const artTime = new Date(now.getTime() + -3 * 60 * 60 * 1000);
  return artTime.toISOString().split("T")[0];
}
