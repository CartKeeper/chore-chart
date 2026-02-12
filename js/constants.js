// Chore Chart - Constants and XP/Rank Definitions

export const RANKS = {
  S: { min: 500, color: '#ffd700', label: 'S - Legendary', pay: 10.00 },
  A: { min: 400, color: '#c0c0c0', label: 'A - Excellent', pay: 8.00 },
  B: { min: 300, color: '#cd7f32', label: 'B - Great', pay: 6.00 },
  C: { min: 200, color: '#4ade80', label: 'C - Good', pay: 4.00 },
  D: { min: 100, color: '#60a5fa', label: 'D - Fair', pay: 2.00 },
  F: { min: 0, color: '#94a3b8', label: 'F - Needs Work', pay: 0.00 }
};

export const STREAK_BONUSES = {
  3: { multiplier: 1.1, label: '3-day streak! +10%' },
  7: { multiplier: 1.25, label: 'Week warrior! +25%' },
  14: { multiplier: 1.5, label: '2-week champion! +50%' },
  30: { multiplier: 2.0, label: 'Monthly legend! +100%' }
};

export const DEFAULT_CHORE_ICONS = [
  '🧹', '🧽', '🧺', '🗑️', '🛏️', '🍽️', '🐕', '🌱',
  '📚', '🎒', '🚿', '🦷', '👕', '🧸', '✨', '🏠'
];

export const DEFAULT_AVATARS = [
  '🧒', '👦', '👧', '🦸', '🦹', '🧙', '🥷', '👸',
  '🤴', '🧝', '🧚', '🦊', '🐱', '🐶', '🦁', '🐼'
];

// Calculate rank from XP
export function getRank(xp) {
  if (xp >= RANKS.S.min) return 'S';
  if (xp >= RANKS.A.min) return 'A';
  if (xp >= RANKS.B.min) return 'B';
  if (xp >= RANKS.C.min) return 'C';
  if (xp >= RANKS.D.min) return 'D';
  return 'F';
}

// Get rank info
export function getRankInfo(xp) {
  const rank = getRank(xp);
  return { rank, ...RANKS[rank] };
}

// Calculate streak multiplier
export function getStreakMultiplier(streak) {
  if (streak >= 30) return STREAK_BONUSES[30];
  if (streak >= 14) return STREAK_BONUSES[14];
  if (streak >= 7) return STREAK_BONUSES[7];
  if (streak >= 3) return STREAK_BONUSES[3];
  return { multiplier: 1.0, label: null };
}

// Calculate total earnings for a week
export function calculateWeeklyEarnings(xp, streak) {
  const rankInfo = getRankInfo(xp);
  const streakInfo = getStreakMultiplier(streak);
  const basePay = rankInfo.pay;
  const total = basePay * streakInfo.multiplier;

  return {
    rank: rankInfo.rank,
    rankLabel: rankInfo.label,
    basePay,
    streakMultiplier: streakInfo.multiplier,
    streakLabel: streakInfo.label,
    total: Math.round(total * 100) / 100
  };
}

// Get week start date (Sunday)
export function getWeekStart(date = new Date()) {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  d.setDate(d.getDate() - d.getDay());
  return d;
}

// Format date as YYYY-MM-DD using LOCAL timezone (not UTC)
// IMPORTANT: toISOString() converts to UTC which shifts the date
// forward after ~4-7pm in US timezones, causing data mismatches.
export function toLocalDateString(d) {
  const date = d instanceof Date ? d : new Date(d);
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

// Format date as YYYY-MM-DD (alias for backward compat)
export function formatDate(date) {
  return toLocalDateString(date);
}

// Get day of week name
export function getDayName(dayNum) {
  const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  return days[dayNum];
}

// Get short day name
export function getShortDayName(dayNum) {
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  return days[dayNum];
}

// Generate a unique ID for offline operations
export function generateOfflineId() {
  return `offline_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
}

// Generate a random 6-digit code
export function generateLinkCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}
