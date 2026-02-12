// Supabase Client Configuration
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { toLocalDateString } from './constants.js';

const SUPABASE_URL = 'https://anksgmvundwmggysztjh.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFua3NnbXZ1bmR3bWdneXN6dGpoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg4ODQ2NjAsImV4cCI6MjA4NDQ2MDY2MH0.opmqicid41-6AY1kQZBHflELZy6ZDKEsRi1fwehGbhA';

// VAPID Public Key for Push Notifications
const VAPID_PUBLIC_KEY = 'BEUL188F_Uj0fESQfe6MVcObVoYwdUunYrmlQH1Ovc8xUmJgNVdSXX33R-35sBw0zP_dLZUhvK4QFi1zrA1ZPCk';

// Use chore_chart schema instead of public
export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  db: { schema: 'chore_chart' }
});

// Device ID management
const DEVICE_ID_KEY = 'chore_chart_device_id';
const USER_KEY = 'chore_chart_user';
const FAMILY_KEY = 'chore_chart_family';
const DEVICE_ROLE_KEY = 'chore_chart_device_role';

export function getDeviceId() {
  let deviceId = localStorage.getItem(DEVICE_ID_KEY);
  if (!deviceId) {
    deviceId = 'device_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
    localStorage.setItem(DEVICE_ID_KEY, deviceId);
  }
  return deviceId;
}

export function getCurrentUser() {
  const data = localStorage.getItem(USER_KEY);
  return data ? JSON.parse(data) : null;
}

export function setCurrentUser(user) {
  if (user) {
    localStorage.setItem(USER_KEY, JSON.stringify(user));
  } else {
    localStorage.removeItem(USER_KEY);
  }
}

export function getCurrentFamily() {
  const data = localStorage.getItem(FAMILY_KEY);
  return data ? JSON.parse(data) : null;
}

export function setCurrentFamily(family) {
  if (family) {
    localStorage.setItem(FAMILY_KEY, JSON.stringify(family));
  } else {
    localStorage.removeItem(FAMILY_KEY);
  }
}

export function getDeviceRole() {
  return localStorage.getItem(DEVICE_ROLE_KEY); // 'parent' or 'child'
}

export function setDeviceRole(role) {
  if (role) {
    localStorage.setItem(DEVICE_ROLE_KEY, role);
  } else {
    localStorage.removeItem(DEVICE_ROLE_KEY);
  }
}

// ============================================
// Family Login (Parent Passcode)
// ============================================

export async function loginParentWithPin(familyName, pin) {
  // Find family by name (case-insensitive)
  const { data: families, error: famError } = await supabase
    .from('families')
    .select('*')
    .ilike('name', familyName);

  if (famError) throw famError;
  if (!families || families.length === 0) return null;

  // Check each matching family for a parent with this PIN
  for (const family of families) {
    const { data: parents, error: userError } = await supabase
      .from('users')
      .select('*')
      .eq('family_id', family.id)
      .eq('type', 'parent')
      .eq('pin_hash', pin);

    if (userError) throw userError;
    if (parents && parents.length > 0) {
      return family;
    }
  }

  return null;
}

// ============================================
// Family Operations
// ============================================

export async function createFamily(name) {
  const { data, error } = await supabase
    .from('families')
    .insert({ name })
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function getFamilyById(familyId) {
  const { data, error } = await supabase
    .from('families')
    .select('*')
    .eq('id', familyId)
    .single();

  if (error) throw error;
  return data;
}

export async function generateFamilyLinkCode(familyId) {
  const code = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes

  const { data, error } = await supabase
    .from('families')
    .update({
      link_code: code,
      link_code_expires_at: expiresAt.toISOString()
    })
    .eq('id', familyId)
    .select()
    .single();

  if (error) throw error;
  return code;
}

export async function findFamilyByLinkCode(code) {
  const { data, error } = await supabase
    .from('families')
    .select('*')
    .eq('link_code', code)
    .gte('link_code_expires_at', new Date().toISOString())
    .single();

  if (error && error.code !== 'PGRST116') throw error;
  return data || null;
}

// ============================================
// User Operations
// ============================================

export async function createUser({ familyId, type, name, avatar, pinHash }) {
  const deviceId = type === 'child' ? getDeviceId() : null;

  const { data, error } = await supabase
    .from('users')
    .insert({
      family_id: familyId,
      type,
      name,
      avatar: avatar || (type === 'child' ? '🧒' : '👤'),
      pin_hash: pinHash,
      device_id: deviceId
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function getUserById(userId) {
  const { data, error } = await supabase
    .from('users')
    .select('*, families(*)')
    .eq('id', userId)
    .single();

  if (error && error.code !== 'PGRST116') throw error;
  return data || null;
}

export async function getUserByDeviceId(deviceId) {
  const { data, error } = await supabase
    .from('users')
    .select('*, families(*)')
    .eq('device_id', deviceId)
    .single();

  if (error && error.code !== 'PGRST116') throw error;
  return data || null;
}

export async function linkDeviceToChild(childId) {
  const deviceId = getDeviceId();

  const { data, error } = await supabase
    .from('users')
    .update({ device_id: deviceId })
    .eq('id', childId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function getFamilyMembers(familyId) {
  const { data, error } = await supabase
    .from('users')
    .select('*')
    .eq('family_id', familyId)
    .order('type', { ascending: false }) // Parents first
    .order('name');

  if (error) throw error;
  return data;
}

export async function getChildren(familyId) {
  const { data, error } = await supabase
    .from('users')
    .select('*')
    .eq('family_id', familyId)
    .eq('type', 'child')
    .order('name');

  if (error) throw error;
  return data;
}

export async function updateUserXP(userId, xpDelta) {
  // Get current XP first
  const { data: user, error: fetchError } = await supabase
    .from('users')
    .select('current_xp')
    .eq('id', userId)
    .single();

  if (fetchError) throw fetchError;

  const newXP = (user.current_xp || 0) + xpDelta;

  const { data, error } = await supabase
    .from('users')
    .update({ current_xp: newXP })
    .eq('id', userId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function updateUserStreak(userId, streak) {
  const { data: user, error: fetchError } = await supabase
    .from('users')
    .select('longest_streak')
    .eq('id', userId)
    .single();

  if (fetchError) throw fetchError;

  const longestStreak = Math.max(user.longest_streak || 0, streak);

  const { data, error } = await supabase
    .from('users')
    .update({
      current_streak: streak,
      longest_streak: longestStreak
    })
    .eq('id', userId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function updateUser(userId, updates) {
  const { data, error } = await supabase
    .from('users')
    .update(updates)
    .eq('id', userId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function deleteUser(userId) {
  const { error } = await supabase
    .from('users')
    .delete()
    .eq('id', userId);

  if (error) throw error;
}

export async function resetChildProgress(childId) {
  // Delete all chore completions for this child
  const { error: compError } = await supabase
    .from('chore_completions')
    .delete()
    .eq('child_id', childId);

  if (compError) throw compError;

  // Delete all nightly completions for this child
  const { error: nightlyError } = await supabase
    .from('nightly_completions')
    .delete()
    .eq('child_id', childId);

  if (nightlyError) throw nightlyError;

  // Delete all bonus task completions for this child
  const { error: bonusError } = await supabase
    .from('bonus_task_completions')
    .delete()
    .eq('child_id', childId);

  if (bonusError) throw bonusError;

  // Reset XP and streaks to zero
  const { error: userError } = await supabase
    .from('users')
    .update({
      current_xp: 0,
      current_streak: 0,
      longest_streak: 0
    })
    .eq('id', childId);

  if (userError) throw userError;
}

// ============================================
// Chore Template Operations
// ============================================

export async function createChoreTemplate({ familyId, name, description, icon, xpValue, createdBy }) {
  const { data, error } = await supabase
    .from('chore_templates')
    .insert({
      family_id: familyId,
      name,
      description,
      icon: icon || '✨',
      xp_value: xpValue || 10,
      created_by: createdBy
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function getChoreTemplates(familyId) {
  const { data, error } = await supabase
    .from('chore_templates')
    .select('*')
    .eq('family_id', familyId)
    .eq('is_active', true)
    .order('name');

  if (error) throw error;
  return data;
}

export async function updateChoreTemplate(templateId, updates) {
  const { data, error } = await supabase
    .from('chore_templates')
    .update(updates)
    .eq('id', templateId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function deleteChoreTemplate(templateId) {
  const { error } = await supabase
    .from('chore_templates')
    .update({ is_active: false })
    .eq('id', templateId);

  if (error) throw error;
}

// ============================================
// Chore Assignment Operations
// ============================================

export async function createChoreAssignment({ templateId, childId, dayOfWeek, recurrenceType, isNightly }) {
  const { data, error } = await supabase
    .from('chore_assignments')
    .insert({
      chore_template_id: templateId,
      child_id: childId,
      day_of_week: dayOfWeek,
      recurrence_type: recurrenceType || 'daily',
      is_nightly: isNightly || false
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function getChildAssignments(childId) {
  const { data, error } = await supabase
    .from('chore_assignments')
    .select(`
      *,
      chore_templates(*)
    `)
    .eq('child_id', childId);

  if (error) throw error;
  return data;
}

export async function getTodaysChores(childId) {
  const today = new Date().getDay(); // 0=Sunday

  const { data: assignments, error } = await supabase
    .from('chore_assignments')
    .select(`
      *,
      chore_templates(*)
    `)
    .eq('child_id', childId);

  if (error) throw error;

  // Filter for today's chores
  return assignments.filter(a => {
    if (!a.chore_templates || !a.chore_templates.is_active) return false;
    if (a.recurrence_type === 'daily') return true;
    if (a.recurrence_type === 'weekly' && a.day_of_week === today) return true;
    return false;
  });
}

export async function deleteChoreAssignment(assignmentId) {
  const { error } = await supabase
    .from('chore_assignments')
    .delete()
    .eq('id', assignmentId);

  if (error) throw error;
}

export async function updateChoreAssignment(assignmentId, updates) {
  const { data, error } = await supabase
    .from('chore_assignments')
    .update(updates)
    .eq('id', assignmentId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

// ============================================
// Chore Completion Operations
// ============================================

export async function completeChore({ assignmentId, childId, xpEarned, offlineId }) {
  const today = new Date();
  const weekStart = new Date(today);
  weekStart.setDate(weekStart.getDate() - weekStart.getDay());

  const { data, error } = await supabase
    .from('chore_completions')
    .insert({
      assignment_id: assignmentId,
      child_id: childId,
      completion_date: toLocalDateString(today),
      week_start: toLocalDateString(weekStart),
      xp_earned: xpEarned,
      offline_id: offlineId
    })
    .select()
    .single();

  if (error) {
    // Check for duplicate (already completed today)
    if (error.code === '23505') {
      return null; // Already completed
    }
    throw error;
  }

  // Update user's XP
  await updateUserXP(childId, xpEarned);

  return data;
}

export async function getTodaysCompletions(childId) {
  const today = toLocalDateString(new Date());

  const { data, error } = await supabase
    .from('chore_completions')
    .select('*')
    .eq('child_id', childId)
    .eq('completion_date', today);

  if (error) throw error;
  return data;
}

export async function getWeeklyCompletions(childId, weekStart) {
  const { data, error } = await supabase
    .from('chore_completions')
    .select(`
      *,
      chore_assignments(*, chore_templates(*))
    `)
    .eq('child_id', childId)
    .eq('week_start', weekStart);

  if (error) throw error;
  return data;
}

export async function getWeeklyXP(childId, weekStart) {
  const { data, error } = await supabase
    .from('chore_completions')
    .select('xp_earned')
    .eq('child_id', childId)
    .eq('week_start', weekStart);

  if (error) throw error;

  return data.reduce((sum, c) => sum + (c.xp_earned || 0), 0);
}

// ============================================
// Reminder Operations
// ============================================

export async function createReminder({ childId, reminderTime, reminderType, message, createdBy }) {
  const insertData = {
    child_id: childId,
    reminder_time: reminderTime,
    reminder_type: reminderType || 'custom',
    message,
    is_active: true
  };

  // Only add created_by if it's provided
  if (createdBy) {
    insertData.created_by = createdBy;
  }

  const { data, error } = await supabase
    .from('reminders')
    .insert(insertData)
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function getChildReminders(childId) {
  const { data, error } = await supabase
    .from('reminders')
    .select('*')
    .eq('child_id', childId)
    .eq('is_active', true)
    .order('reminder_time');

  if (error) throw error;
  return data;
}

export async function updateReminder(reminderId, updates) {
  const { data, error } = await supabase
    .from('reminders')
    .update(updates)
    .eq('id', reminderId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function deleteReminder(reminderId) {
  const { error } = await supabase
    .from('reminders')
    .update({ is_active: false })
    .eq('id', reminderId);

  if (error) throw error;
}

// ============================================
// Weekly Earnings Operations
// ============================================

export async function getOrCreateWeeklyEarnings(childId, weekStart) {
  // Try to get existing record
  const { data: existing, error: fetchError } = await supabase
    .from('weekly_earnings')
    .select('*')
    .eq('child_id', childId)
    .eq('week_start', weekStart)
    .single();

  if (existing) return existing;
  if (fetchError && fetchError.code !== 'PGRST116') throw fetchError;

  // Create new record
  const { data, error } = await supabase
    .from('weekly_earnings')
    .insert({
      child_id: childId,
      week_start: weekStart
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function updateWeeklyEarnings(earningsId, updates) {
  const { data, error } = await supabase
    .from('weekly_earnings')
    .update(updates)
    .eq('id', earningsId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function markEarningsPaid(earningsId, paidBy) {
  const { data, error } = await supabase
    .from('weekly_earnings')
    .update({
      paid_at: new Date().toISOString(),
      paid_by: paidBy
    })
    .eq('id', earningsId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

// ============================================
// Achievement Operations
// ============================================

export async function getAchievements(familyId) {
  const { data, error } = await supabase
    .from('achievements')
    .select('*')
    .or(`family_id.eq.${familyId},is_default.eq.true`)
    .order('criteria_type')
    .order('name');

  if (error) throw error;
  return data;
}

export async function getChildAchievementUnlocks(childId) {
  const { data, error } = await supabase
    .from('achievement_unlocks')
    .select(`
      *,
      achievements(*)
    `)
    .eq('child_id', childId);

  if (error) throw error;
  return data;
}

export async function unlockAchievement(childId, achievementId) {
  const { data, error } = await supabase
    .from('achievement_unlocks')
    .insert({
      child_id: childId,
      achievement_id: achievementId
    })
    .select(`
      *,
      achievements(*)
    `)
    .single();

  if (error) {
    // Already unlocked
    if (error.code === '23505') return null;
    throw error;
  }
  return data;
}

export async function claimAchievementReward(unlockId) {
  const { data, error } = await supabase
    .from('achievement_unlocks')
    .update({ reward_paid: true })
    .eq('id', unlockId)
    .select(`
      *,
      achievements(*)
    `)
    .single();

  if (error) throw error;
  return data;
}

// Reset achievement unlocks for a child
export async function resetAchievements(childId) {
  const { error } = await supabase
    .from('achievement_unlocks')
    .delete()
    .eq('child_id', childId);

  if (error) throw error;
}

// Reset privilege unlocks for a child
export async function resetPrivileges(childId) {
  const { error } = await supabase
    .from('privilege_unlocks')
    .delete()
    .eq('child_id', childId);

  if (error) throw error;
}

// ============================================
// Privileges
// ============================================

export async function getPrivileges(familyId) {
  const { data, error } = await supabase
    .from('privileges')
    .select('*')
    .eq('family_id', familyId);

  if (error) throw error;
  return data || [];
}

export async function createPrivilege(privilege) {
  const { data, error } = await supabase
    .from('privileges')
    .insert(privilege)
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function getChildPrivilegeUnlocks(childId) {
  const { data, error } = await supabase
    .from('privilege_unlocks')
    .select(`
      *,
      privileges(*)
    `)
    .eq('child_id', childId);

  if (error) throw error;
  return data || [];
}

export async function unlockPrivilege(childId, privilegeId) {
  const { data, error } = await supabase
    .from('privilege_unlocks')
    .insert({
      child_id: childId,
      privilege_id: privilegeId
    })
    .select(`
      *,
      privileges(*)
    `)
    .single();

  if (error) {
    if (error.code === '23505') return null;
    throw error;
  }
  return data;
}

export async function usePrivilege(unlockId) {
  const { data, error } = await supabase
    .from('privilege_unlocks')
    .update({ used_at: new Date().toISOString() })
    .eq('id', unlockId)
    .select(`
      *,
      privileges(*)
    `)
    .single();

  if (error) throw error;
  return data;
}

// ============================================
// Bonus Tasks (Money Makers)
// ============================================

export async function getBonusTasks(familyId) {
  const { data, error } = await supabase
    .from('bonus_tasks')
    .select('*')
    .eq('family_id', familyId)
    .eq('is_active', true)
    .order('created_at', { ascending: false });

  if (error) throw error;
  return data || [];
}

export async function createBonusTask({ familyId, name, description, icon, amount, xpValue, createdBy }) {
  const { data, error } = await supabase
    .from('bonus_tasks')
    .insert({
      family_id: familyId,
      name,
      description,
      icon,
      amount: amount || 0,
      xp_value: xpValue || 10,
      created_by: createdBy
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function updateBonusTask(taskId, updates) {
  const { data, error } = await supabase
    .from('bonus_tasks')
    .update(updates)
    .eq('id', taskId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function deleteBonusTask(taskId) {
  const { error } = await supabase
    .from('bonus_tasks')
    .delete()
    .eq('id', taskId);

  if (error) throw error;
}

export async function getBonusTaskCompletions(childId, weekStart) {
  const { data, error } = await supabase
    .from('bonus_task_completions')
    .select('*, bonus_tasks(*)')
    .eq('child_id', childId)
    .eq('week_start', weekStart);

  if (error) throw error;
  return data || [];
}

export async function completeBonusTask({ taskId, childId, weekStart, xpEarned, amountEarned }) {
  const { data, error } = await supabase
    .from('bonus_task_completions')
    .insert({
      bonus_task_id: taskId,
      child_id: childId,
      week_start: weekStart,
      xp_earned: xpEarned,
      amount_earned: amountEarned
    })
    .select('*, bonus_tasks(*)')
    .single();

  if (error) {
    if (error.code === '23505') return null; // Already completed this week
    throw error;
  }
  return data;
}

// Request a bonus task completion (pending approval) — once per day
export async function requestBonusTask({ taskId, childId, weekStart }) {
  const today = toLocalDateString(new Date());
  const { data, error } = await supabase
    .from('bonus_task_completions')
    .insert({
      bonus_task_id: taskId,
      child_id: childId,
      week_start: weekStart,
      completion_date: today,
      xp_earned: 0,
      amount_earned: 0,
      status: 'pending'
    })
    .select('*, bonus_tasks(*)')
    .single();

  if (error) {
    if (error.code === '23505') return null; // Already requested/completed today
    throw error;
  }
  return data;
}

// Approve a pending bonus task — awards XP and money
export async function approveBonusTask(completionId, xpEarned, amountEarned) {
  const { data, error } = await supabase
    .from('bonus_task_completions')
    .update({
      status: 'approved',
      xp_earned: xpEarned,
      amount_earned: amountEarned
    })
    .eq('id', completionId)
    .select('*, bonus_tasks(*)')
    .single();

  if (error) throw error;

  // Award XP
  await updateUserXP(data.child_id, xpEarned);

  return data;
}

// Deny a pending bonus task — removes the record
export async function denyBonusTask(completionId) {
  const { error } = await supabase
    .from('bonus_task_completions')
    .delete()
    .eq('id', completionId);

  if (error) throw error;
}

// Get all pending bonus task requests for a family
export async function getPendingBonusTasks(familyId) {
  // Get all children in the family
  const { data: familyChildren, error: childError } = await supabase
    .from('users')
    .select('id, name, avatar')
    .eq('family_id', familyId)
    .eq('type', 'child');

  if (childError) throw childError;
  if (!familyChildren || familyChildren.length === 0) return [];

  const childIds = familyChildren.map(c => c.id);
  const childMap = {};
  familyChildren.forEach(c => { childMap[c.id] = c; });

  const { data, error } = await supabase
    .from('bonus_task_completions')
    .select('*, bonus_tasks(*)')
    .in('child_id', childIds)
    .eq('status', 'pending')
    .order('completed_at', { ascending: false });

  if (error) throw error;

  // Attach child info manually to avoid FK join issues
  return (data || []).map(d => ({
    ...d,
    users: childMap[d.child_id] || { name: 'Unknown', avatar: '🧒' }
  }));
}

// ============================================
// Nightly Zones (Database-synced)
// ============================================

export async function getNightlyZonesFromDB(familyId) {
  const { data, error } = await supabase
    .from('nightly_zones')
    .select('*')
    .eq('family_id', familyId)
    .order('sort_order', { ascending: true });

  if (error) {
    // Table might not exist yet
    if (error.code === '42P01') return [];
    throw error;
  }
  return data || [];
}

export async function createNightlyZone({ familyId, zoneKey, name, icon, sortOrder = 0 }) {
  const { data, error } = await supabase
    .from('nightly_zones')
    .insert({
      family_id: familyId,
      zone_key: zoneKey,
      name,
      icon,
      sort_order: sortOrder
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function updateNightlyZone(zoneId, updates) {
  const { data, error } = await supabase
    .from('nightly_zones')
    .update(updates)
    .eq('id', zoneId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function deleteNightlyZone(zoneId) {
  const { error } = await supabase
    .from('nightly_zones')
    .delete()
    .eq('id', zoneId);

  if (error) throw error;
}

export async function getNightlyCompletions(childId, weekStart) {
  const { data, error } = await supabase
    .from('nightly_completions')
    .select(`
      *,
      nightly_zones(*)
    `)
    .eq('child_id', childId)
    .eq('week_start', weekStart);

  if (error) {
    // Table might not exist yet
    if (error.code === '42P01') return [];
    throw error;
  }
  return data || [];
}

export async function completeNightlyZone({ childId, zoneId, weekStart, dayOfWeek }) {
  const { data, error } = await supabase
    .from('nightly_completions')
    .insert({
      child_id: childId,
      zone_id: zoneId,
      week_start: weekStart,
      day_of_week: dayOfWeek
    })
    .select()
    .single();

  if (error) {
    if (error.code === '23505') return null; // Already completed
    throw error;
  }
  return data;
}

// ============================================
// Real-time Subscriptions
// ============================================

export function subscribeToCompletions(familyId, callback) {
  return supabase
    .channel('completions')
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'chore_completions'
      },
      (payload) => callback(payload.new)
    )
    .subscribe();
}

export function subscribeToUserUpdates(userId, callback) {
  return supabase
    .channel(`user-${userId}`)
    .on(
      'postgres_changes',
      {
        event: 'UPDATE',
        schema: 'public',
        table: 'users',
        filter: `id=eq.${userId}`
      },
      (payload) => callback(payload.new)
    )
    .subscribe();
}

// ============================================
// Push Notification Functions
// ============================================

// Convert VAPID key from base64 to Uint8Array
function urlBase64ToUint8Array(base64String) {
  const padding = '='.repeat((4 - base64String.length % 4) % 4);
  const base64 = (base64String + padding)
    .replace(/-/g, '+')
    .replace(/_/g, '/');
  const rawData = window.atob(base64);
  const outputArray = new Uint8Array(rawData.length);
  for (let i = 0; i < rawData.length; ++i) {
    outputArray[i] = rawData.charCodeAt(i);
  }
  return outputArray;
}

// Check if push notifications are supported
export function isPushSupported() {
  return 'serviceWorker' in navigator && 'PushManager' in window;
}

// Get current push subscription status
export async function getPushSubscription() {
  if (!isPushSupported()) return null;
  const registration = await navigator.serviceWorker.ready;
  return await registration.pushManager.getSubscription();
}

// Subscribe to push notifications
export async function subscribeToPush(userId) {
  if (!isPushSupported()) {
    throw new Error('Push notifications not supported');
  }

  // Request permission
  const permission = await Notification.requestPermission();
  if (permission !== 'granted') {
    throw new Error('Notification permission denied');
  }

  // Get service worker registration
  const registration = await navigator.serviceWorker.ready;

  // Subscribe to push
  const subscription = await registration.pushManager.subscribe({
    userVisibleOnly: true,
    applicationServerKey: urlBase64ToUint8Array(VAPID_PUBLIC_KEY)
  });

  // Save subscription to database
  const subscriptionJson = subscription.toJSON();
  const { error } = await supabase
    .from('users')
    .update({ push_subscription: subscriptionJson })
    .eq('id', userId);

  if (error) throw error;

  return subscription;
}

// Unsubscribe from push notifications
export async function unsubscribeFromPush(userId) {
  const subscription = await getPushSubscription();
  if (subscription) {
    await subscription.unsubscribe();
  }

  // Remove from database
  const { error } = await supabase
    .from('users')
    .update({ push_subscription: null })
    .eq('id', userId);

  if (error) throw error;
}
