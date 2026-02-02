-- Chore Chart Database Schema
-- Run this in Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TABLES
-- ============================================

-- 1. Families - Family groups
CREATE TABLE families (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  link_code TEXT UNIQUE, -- 6-digit code for device linking
  link_code_expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Users - Parents and children
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  family_id UUID REFERENCES families(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('parent', 'child')),
  name TEXT NOT NULL,
  pin_hash TEXT, -- For parent auth (bcrypt)
  avatar TEXT DEFAULT '🧒', -- Emoji or image URL
  push_subscription JSONB, -- Web Push subscription data
  device_id TEXT, -- For linking devices
  current_xp INT DEFAULT 0,
  current_streak INT DEFAULT 0,
  longest_streak INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Chore Templates - Parent-defined chores
CREATE TABLE chore_templates (
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

-- 4. Chore Assignments - Scheduled chores
CREATE TABLE chore_assignments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chore_template_id UUID REFERENCES chore_templates(id) ON DELETE CASCADE NOT NULL,
  child_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  day_of_week INT CHECK (day_of_week >= 0 AND day_of_week <= 6), -- 0=Sun, 6=Sat, NULL=daily
  recurrence_type TEXT DEFAULT 'daily' CHECK (recurrence_type IN ('weekly', 'daily', 'one-time')),
  is_nightly BOOLEAN DEFAULT FALSE, -- For nightly patrol type
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Chore Completions - Completion log
CREATE TABLE chore_completions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  assignment_id UUID REFERENCES chore_assignments(id) ON DELETE CASCADE NOT NULL,
  child_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  completion_date DATE NOT NULL DEFAULT CURRENT_DATE,
  week_start DATE NOT NULL,
  completed_at TIMESTAMPTZ DEFAULT NOW(),
  xp_earned INT NOT NULL,
  verified_by UUID REFERENCES users(id), -- Parent verification (optional)
  offline_id TEXT, -- For offline sync deduplication
  UNIQUE(assignment_id, completion_date) -- Prevent duplicate completions per day
);

-- 6. Reminders - Parent-configured reminders
CREATE TABLE reminders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  reminder_time TIME NOT NULL, -- e.g., "20:00"
  reminder_type TEXT DEFAULT 'custom' CHECK (reminder_type IN ('nightly', 'morning', 'custom')),
  message TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Weekly Earnings - Pay history
CREATE TABLE weekly_earnings (
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

-- 8. Achievements - Achievement definitions
CREATE TABLE achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  family_id UUID REFERENCES families(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT DEFAULT '🏆',
  reward_amount DECIMAL(10,2) DEFAULT 0,
  criteria_type TEXT CHECK (criteria_type IN ('xp_threshold', 'streak', 'completion_count', 'custom')),
  criteria_value JSONB, -- e.g., {"xp": 1000} or {"streak": 7}
  is_default BOOLEAN DEFAULT FALSE, -- System achievement vs custom
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. Achievement Unlocks - Child achievement history
CREATE TABLE achievement_unlocks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  achievement_id UUID REFERENCES achievements(id) ON DELETE CASCADE NOT NULL,
  unlocked_at TIMESTAMPTZ DEFAULT NOW(),
  reward_paid BOOLEAN DEFAULT FALSE,
  UNIQUE(child_id, achievement_id)
);

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX idx_users_family ON users(family_id);
CREATE INDEX idx_users_device ON users(device_id);
CREATE INDEX idx_chore_templates_family ON chore_templates(family_id);
CREATE INDEX idx_chore_assignments_child ON chore_assignments(child_id);
CREATE INDEX idx_chore_assignments_template ON chore_assignments(chore_template_id);
CREATE INDEX idx_chore_completions_child ON chore_completions(child_id);
CREATE INDEX idx_chore_completions_date ON chore_completions(completion_date);
CREATE INDEX idx_chore_completions_week ON chore_completions(week_start);
CREATE INDEX idx_chore_completions_offline ON chore_completions(offline_id);
CREATE INDEX idx_weekly_earnings_child ON weekly_earnings(child_id);
CREATE INDEX idx_weekly_earnings_week ON weekly_earnings(week_start);
CREATE INDEX idx_achievement_unlocks_child ON achievement_unlocks(child_id);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
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

-- For now, allow all operations (we'll use device_id for auth)
-- In production, you'd want proper JWT-based auth

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
-- DEFAULT ACHIEVEMENTS
-- ============================================

INSERT INTO achievements (name, description, icon, criteria_type, criteria_value, is_default) VALUES
('First Quest', 'Complete your first chore', '⭐', 'completion_count', '{"count": 1}', true),
('Getting Started', 'Earn 100 XP', '🌟', 'xp_threshold', '{"xp": 100}', true),
('Rising Star', 'Earn 500 XP', '💫', 'xp_threshold', '{"xp": 500}', true),
('XP Master', 'Earn 1000 XP', '🌠', 'xp_threshold', '{"xp": 1000}', true),
('Legend', 'Earn 5000 XP', '👑', 'xp_threshold', '{"xp": 5000}', true),
('Streak Starter', 'Get a 3-day streak', '🔥', 'streak', '{"days": 3}', true),
('Week Warrior', 'Get a 7-day streak', '⚡', 'streak', '{"days": 7}', true),
('Streak Champion', 'Get a 14-day streak', '💪', 'streak', '{"days": 14}', true),
('Unstoppable', 'Get a 30-day streak', '🏆', 'streak', '{"days": 30}', true);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to get the start of the current week (Sunday)
CREATE OR REPLACE FUNCTION get_week_start(d DATE DEFAULT CURRENT_DATE)
RETURNS DATE AS $$
BEGIN
  RETURN d - EXTRACT(DOW FROM d)::INT;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to generate a random 6-digit link code
CREATE OR REPLACE FUNCTION generate_link_code()
RETURNS TEXT AS $$
BEGIN
  RETURN LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
END;
$$ LANGUAGE plpgsql;

-- Function to calculate rank based on weekly XP
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

-- Function to calculate base pay based on rank
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
