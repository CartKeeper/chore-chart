-- Chore Chart - Migration Script
-- Run this if you already have some tables from a previous version

-- Enable UUID extension (safe to run multiple times)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- ADD MISSING COLUMNS TO EXISTING TABLES
-- ============================================

-- Add columns to families if they don't exist
ALTER TABLE families ADD COLUMN IF NOT EXISTS link_code TEXT UNIQUE;
ALTER TABLE families ADD COLUMN IF NOT EXISTS link_code_expires_at TIMESTAMPTZ;

-- Add columns to users if they don't exist
ALTER TABLE users ADD COLUMN IF NOT EXISTS device_id TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS push_subscription JSONB;
ALTER TABLE users ADD COLUMN IF NOT EXISTS current_xp INT DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS current_streak INT DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS longest_streak INT DEFAULT 0;

-- ============================================
-- CREATE TABLES IF THEY DON'T EXIST
-- ============================================

-- Chore Templates
CREATE TABLE IF NOT EXISTS chore_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  family_id UUID REFERENCES families(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT DEFAULT '✨',
  xp_value INT DEFAULT 10,
  created_by UUID REFERENCES users(id),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Chore Assignments
CREATE TABLE IF NOT EXISTS chore_assignments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chore_template_id UUID REFERENCES chore_templates(id) ON DELETE CASCADE NOT NULL,
  child_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  day_of_week INT CHECK (day_of_week >= 0 AND day_of_week <= 6),
  recurrence_type TEXT DEFAULT 'daily' CHECK (recurrence_type IN ('weekly', 'daily', 'one-time')),
  is_nightly BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Chore Completions
CREATE TABLE IF NOT EXISTS chore_completions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  assignment_id UUID REFERENCES chore_assignments(id) ON DELETE CASCADE NOT NULL,
  child_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  completion_date DATE NOT NULL DEFAULT CURRENT_DATE,
  week_start DATE NOT NULL,
  completed_at TIMESTAMPTZ DEFAULT NOW(),
  xp_earned INT NOT NULL,
  verified_by UUID REFERENCES users(id),
  offline_id TEXT,
  UNIQUE(assignment_id, completion_date)
);

-- Reminders
CREATE TABLE IF NOT EXISTS reminders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  reminder_time TIME NOT NULL,
  reminder_type TEXT DEFAULT 'custom' CHECK (reminder_type IN ('nightly', 'morning', 'custom')),
  message TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Weekly Earnings
CREATE TABLE IF NOT EXISTS weekly_earnings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  week_start DATE NOT NULL,
  total_xp INT DEFAULT 0,
  rank TEXT,
  base_pay DECIMAL(10,2) DEFAULT 0,
  streak_multiplier DECIMAL(3,2) DEFAULT 1.00,
  bonus_amount DECIMAL(10,2) DEFAULT 0,
  total_earned DECIMAL(10,2) DEFAULT 0,
  paid_at TIMESTAMPTZ,
  paid_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(child_id, week_start)
);

-- Achievements
CREATE TABLE IF NOT EXISTS achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  family_id UUID REFERENCES families(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT DEFAULT '🏆',
  reward_amount DECIMAL(10,2) DEFAULT 0,
  criteria_type TEXT CHECK (criteria_type IN ('xp_threshold', 'streak', 'completion_count', 'custom')),
  criteria_value JSONB,
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Achievement Unlocks
CREATE TABLE IF NOT EXISTS achievement_unlocks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  achievement_id UUID REFERENCES achievements(id) ON DELETE CASCADE NOT NULL,
  unlocked_at TIMESTAMPTZ DEFAULT NOW(),
  reward_paid BOOLEAN DEFAULT FALSE,
  UNIQUE(child_id, achievement_id)
);

-- ============================================
-- INDEXES (safe to run - will skip if exists)
-- ============================================

CREATE INDEX IF NOT EXISTS idx_users_family ON users(family_id);
CREATE INDEX IF NOT EXISTS idx_users_device ON users(device_id);
CREATE INDEX IF NOT EXISTS idx_chore_templates_family ON chore_templates(family_id);
CREATE INDEX IF NOT EXISTS idx_chore_assignments_child ON chore_assignments(child_id);
CREATE INDEX IF NOT EXISTS idx_chore_assignments_template ON chore_assignments(chore_template_id);
CREATE INDEX IF NOT EXISTS idx_chore_completions_child ON chore_completions(child_id);
CREATE INDEX IF NOT EXISTS idx_chore_completions_date ON chore_completions(completion_date);
CREATE INDEX IF NOT EXISTS idx_chore_completions_week ON chore_completions(week_start);
CREATE INDEX IF NOT EXISTS idx_chore_completions_offline ON chore_completions(offline_id);
CREATE INDEX IF NOT EXISTS idx_weekly_earnings_child ON weekly_earnings(child_id);
CREATE INDEX IF NOT EXISTS idx_weekly_earnings_week ON weekly_earnings(week_start);
CREATE INDEX IF NOT EXISTS idx_achievement_unlocks_child ON achievement_unlocks(child_id);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE chore_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE chore_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE chore_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_earnings ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievement_unlocks ENABLE ROW LEVEL SECURITY;

-- Policies (drop and recreate to avoid conflicts)
DROP POLICY IF EXISTS "Allow all on families" ON families;
DROP POLICY IF EXISTS "Allow all on users" ON users;
DROP POLICY IF EXISTS "Allow all on chore_templates" ON chore_templates;
DROP POLICY IF EXISTS "Allow all on chore_assignments" ON chore_assignments;
DROP POLICY IF EXISTS "Allow all on chore_completions" ON chore_completions;
DROP POLICY IF EXISTS "Allow all on reminders" ON reminders;
DROP POLICY IF EXISTS "Allow all on weekly_earnings" ON weekly_earnings;
DROP POLICY IF EXISTS "Allow all on achievements" ON achievements;
DROP POLICY IF EXISTS "Allow all on achievement_unlocks" ON achievement_unlocks;

CREATE POLICY "Allow all on families" ON families FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on users" ON users FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on chore_templates" ON chore_templates FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on chore_assignments" ON chore_assignments FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on chore_completions" ON chore_completions FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on reminders" ON reminders FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on weekly_earnings" ON weekly_earnings FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on achievements" ON achievements FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on achievement_unlocks" ON achievement_unlocks FOR ALL USING (true) WITH CHECK (true);

-- ============================================
-- DEFAULT ACHIEVEMENTS (insert if not exists)
-- ============================================

INSERT INTO achievements (name, description, icon, criteria_type, criteria_value, is_default)
SELECT 'First Quest', 'Complete your first chore', '⭐', 'completion_count', '{"count": 1}', true
WHERE NOT EXISTS (SELECT 1 FROM achievements WHERE name = 'First Quest' AND is_default = true);

INSERT INTO achievements (name, description, icon, criteria_type, criteria_value, is_default)
SELECT 'Getting Started', 'Earn 100 XP', '🌟', 'xp_threshold', '{"xp": 100}', true
WHERE NOT EXISTS (SELECT 1 FROM achievements WHERE name = 'Getting Started' AND is_default = true);

INSERT INTO achievements (name, description, icon, criteria_type, criteria_value, is_default)
SELECT 'Rising Star', 'Earn 500 XP', '💫', 'xp_threshold', '{"xp": 500}', true
WHERE NOT EXISTS (SELECT 1 FROM achievements WHERE name = 'Rising Star' AND is_default = true);

INSERT INTO achievements (name, description, icon, criteria_type, criteria_value, is_default)
SELECT 'XP Master', 'Earn 1000 XP', '🌠', 'xp_threshold', '{"xp": 1000}', true
WHERE NOT EXISTS (SELECT 1 FROM achievements WHERE name = 'XP Master' AND is_default = true);

INSERT INTO achievements (name, description, icon, criteria_type, criteria_value, is_default)
SELECT 'Legend', 'Earn 5000 XP', '👑', 'xp_threshold', '{"xp": 5000}', true
WHERE NOT EXISTS (SELECT 1 FROM achievements WHERE name = 'Legend' AND is_default = true);

INSERT INTO achievements (name, description, icon, criteria_type, criteria_value, is_default)
SELECT 'Streak Starter', 'Get a 3-day streak', '🔥', 'streak', '{"days": 3}', true
WHERE NOT EXISTS (SELECT 1 FROM achievements WHERE name = 'Streak Starter' AND is_default = true);

INSERT INTO achievements (name, description, icon, criteria_type, criteria_value, is_default)
SELECT 'Week Warrior', 'Get a 7-day streak', '⚡', 'streak', '{"days": 7}', true
WHERE NOT EXISTS (SELECT 1 FROM achievements WHERE name = 'Week Warrior' AND is_default = true);

INSERT INTO achievements (name, description, icon, criteria_type, criteria_value, is_default)
SELECT 'Streak Champion', 'Get a 14-day streak', '💪', 'streak', '{"days": 14}', true
WHERE NOT EXISTS (SELECT 1 FROM achievements WHERE name = 'Streak Champion' AND is_default = true);

INSERT INTO achievements (name, description, icon, criteria_type, criteria_value, is_default)
SELECT 'Unstoppable', 'Get a 30-day streak', '🏆', 'streak', '{"days": 30}', true
WHERE NOT EXISTS (SELECT 1 FROM achievements WHERE name = 'Unstoppable' AND is_default = true);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

CREATE OR REPLACE FUNCTION get_week_start(d DATE DEFAULT CURRENT_DATE)
RETURNS DATE AS $$
BEGIN
  RETURN d - EXTRACT(DOW FROM d)::INT;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION generate_link_code()
RETURNS TEXT AS $$
BEGIN
  RETURN LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION calculate_rank(xp INT)
RETURNS TEXT AS $$
BEGIN
  IF xp >= 500 THEN RETURN 'S';
  ELSIF xp >= 400 THEN RETURN 'A';
  ELSIF xp >= 300 THEN RETURN 'B';
  ELSIF xp >= 200 THEN RETURN 'C';
  ELSIF xp >= 100 THEN RETURN 'D';
  ELSE RETURN 'F';
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION calculate_base_pay(rank TEXT)
RETURNS DECIMAL AS $$
BEGIN
  CASE rank
    WHEN 'S' THEN RETURN 10.00;
    WHEN 'A' THEN RETURN 8.00;
    WHEN 'B' THEN RETURN 6.00;
    WHEN 'C' THEN RETURN 4.00;
    WHEN 'D' THEN RETURN 2.00;
    ELSE RETURN 0.00;
  END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
