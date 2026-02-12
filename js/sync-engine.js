// Offline-first Sync Engine for Chore Chart
import { supabase, completeChore } from './supabase-client.js';
import { generateOfflineId, toLocalDateString } from './constants.js';

const PENDING_QUEUE_KEY = 'chore_chart_pending_queue';
const CACHE_KEY = 'chore_chart_cache';

// ============================================
// Pending Queue Management
// ============================================

function getPendingQueue() {
  const data = localStorage.getItem(PENDING_QUEUE_KEY);
  return data ? JSON.parse(data) : [];
}

function savePendingQueue(queue) {
  localStorage.setItem(PENDING_QUEUE_KEY, JSON.stringify(queue));
}

function addToPendingQueue(action) {
  const queue = getPendingQueue();
  queue.push({
    ...action,
    id: generateOfflineId(),
    createdAt: new Date().toISOString()
  });
  savePendingQueue(queue);
}

function removeFromPendingQueue(id) {
  const queue = getPendingQueue();
  const filtered = queue.filter(item => item.id !== id);
  savePendingQueue(filtered);
}

// ============================================
// Cache Management
// ============================================

function getCache() {
  const data = localStorage.getItem(CACHE_KEY);
  return data ? JSON.parse(data) : {};
}

function setCache(key, value) {
  const cache = getCache();
  cache[key] = {
    data: value,
    timestamp: Date.now()
  };
  localStorage.setItem(CACHE_KEY, JSON.stringify(cache));
}

function getCached(key, maxAge = 5 * 60 * 1000) { // 5 minutes default
  const cache = getCache();
  const entry = cache[key];
  if (!entry) return null;
  if (Date.now() - entry.timestamp > maxAge) return null;
  return entry.data;
}

function clearCache() {
  localStorage.removeItem(CACHE_KEY);
}

// ============================================
// Offline Chore Completion
// ============================================

export async function completeChoreOffline(assignmentId, childId, xpEarned) {
  const offlineId = generateOfflineId();
  const today = toLocalDateString(new Date());

  // Add to pending queue
  addToPendingQueue({
    type: 'COMPLETE_CHORE',
    payload: {
      assignmentId,
      childId,
      xpEarned,
      offlineId,
      completionDate: today
    }
  });

  // Update local cache for immediate UI feedback
  const cacheKey = `completions_${childId}_${today}`;
  const cached = getCached(cacheKey) || [];
  cached.push({
    id: offlineId,
    assignment_id: assignmentId,
    child_id: childId,
    xp_earned: xpEarned,
    completion_date: today,
    offline_id: offlineId,
    pending: true
  });
  setCache(cacheKey, cached);

  // Try to sync immediately if online
  if (navigator.onLine) {
    await syncPendingQueue();
  }

  return offlineId;
}

// ============================================
// Sync Engine
// ============================================

export async function syncPendingQueue() {
  if (!navigator.onLine) return { synced: 0, failed: 0 };

  const queue = getPendingQueue();
  if (queue.length === 0) return { synced: 0, failed: 0 };

  let synced = 0;
  let failed = 0;

  for (const action of queue) {
    try {
      if (action.type === 'COMPLETE_CHORE') {
        const result = await completeChore({
          assignmentId: action.payload.assignmentId,
          childId: action.payload.childId,
          xpEarned: action.payload.xpEarned,
          offlineId: action.payload.offlineId
        });

        if (result !== null) {
          synced++;
        }
        removeFromPendingQueue(action.id);
      }
    } catch (error) {
      console.error('Sync error for action:', action.id, error);
      failed++;
      // Don't remove from queue - will retry later
    }
  }

  return { synced, failed };
}

// ============================================
// Auto-sync on Online
// ============================================

let syncInProgress = false;
let syncCallbacks = [];

export function onSyncComplete(callback) {
  syncCallbacks.push(callback);
}

export function offSyncComplete(callback) {
  syncCallbacks = syncCallbacks.filter(cb => cb !== callback);
}

async function handleOnline() {
  if (syncInProgress) return;
  syncInProgress = true;

  try {
    const result = await syncPendingQueue();
    syncCallbacks.forEach(cb => cb(result));
  } finally {
    syncInProgress = false;
  }
}

// Setup listeners
if (typeof window !== 'undefined') {
  window.addEventListener('online', handleOnline);

  // Also sync periodically when online
  setInterval(() => {
    if (navigator.onLine && !syncInProgress) {
      handleOnline();
    }
  }, 30000); // Every 30 seconds
}

// ============================================
// Data Fetching with Offline Support
// ============================================

export async function fetchWithOffline(fetchFn, cacheKey, maxAge = 5 * 60 * 1000) {
  // Try cache first if offline
  if (!navigator.onLine) {
    const cached = getCached(cacheKey, Infinity); // Use cache regardless of age when offline
    if (cached) return { data: cached, fromCache: true, offline: true };
    throw new Error('Offline and no cached data available');
  }

  // Online: try fetch, fall back to cache
  try {
    const data = await fetchFn();
    setCache(cacheKey, data);
    return { data, fromCache: false, offline: false };
  } catch (error) {
    const cached = getCached(cacheKey, maxAge);
    if (cached) return { data: cached, fromCache: true, offline: false };
    throw error;
  }
}

// ============================================
// Pending Status
// ============================================

export function getPendingCount() {
  return getPendingQueue().length;
}

export function hasPendingSync() {
  return getPendingQueue().length > 0;
}

export function getPendingCompletions(childId, date) {
  const queue = getPendingQueue();
  return queue
    .filter(a =>
      a.type === 'COMPLETE_CHORE' &&
      a.payload.childId === childId &&
      a.payload.completionDate === date
    )
    .map(a => a.payload.assignmentId);
}

// ============================================
// Export for debugging
// ============================================

export const debugSync = {
  getQueue: getPendingQueue,
  getCache,
  clearCache,
  clearQueue: () => savePendingQueue([]),
  forceSync: syncPendingQueue
};
