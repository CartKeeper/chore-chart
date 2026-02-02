-- Add rewards to default achievements
-- Run this in Supabase SQL Editor

-- Update existing achievements with reward amounts
UPDATE chore_chart.achievements SET reward_amount = 0.50 WHERE name = 'First Quest' AND is_default = true;
UPDATE chore_chart.achievements SET reward_amount = 1.00 WHERE name = 'Getting Started' AND is_default = true;
UPDATE chore_chart.achievements SET reward_amount = 2.00 WHERE name = 'Rising Star' AND is_default = true;
UPDATE chore_chart.achievements SET reward_amount = 5.00 WHERE name = 'XP Master' AND is_default = true;
UPDATE chore_chart.achievements SET reward_amount = 10.00 WHERE name = 'Legend' AND is_default = true;
UPDATE chore_chart.achievements SET reward_amount = 1.00 WHERE name = 'Streak Starter' AND is_default = true;
UPDATE chore_chart.achievements SET reward_amount = 2.00 WHERE name = 'Week Warrior' AND is_default = true;
UPDATE chore_chart.achievements SET reward_amount = 3.00 WHERE name = 'Streak Champion' AND is_default = true;
UPDATE chore_chart.achievements SET reward_amount = 5.00 WHERE name = 'Unstoppable' AND is_default = true;

-- Add new achievements with tiered rewards
INSERT INTO chore_chart.achievements (name, description, icon, criteria_type, criteria_value, reward_amount, is_default)
SELECT 'Perfect Week', 'Complete all chores for a full week', '🌟', 'custom', '{"type": "perfect_week"}', 3.00, true
WHERE NOT EXISTS (SELECT 1 FROM chore_chart.achievements WHERE name = 'Perfect Week' AND is_default = true);

INSERT INTO chore_chart.achievements (name, description, icon, criteria_type, criteria_value, reward_amount, is_default)
SELECT 'Early Bird', 'Complete morning chores before 9 AM for 5 days', '🌅', 'custom', '{"type": "early_bird", "days": 5}', 2.00, true
WHERE NOT EXISTS (SELECT 1 FROM chore_chart.achievements WHERE name = 'Early Bird' AND is_default = true);

INSERT INTO chore_chart.achievements (name, description, icon, criteria_type, criteria_value, reward_amount, is_default)
SELECT 'Night Owl', 'Complete nightly patrol for 7 consecutive days', '🦉', 'custom', '{"type": "nightly_streak", "days": 7}', 2.00, true
WHERE NOT EXISTS (SELECT 1 FROM chore_chart.achievements WHERE name = 'Night Owl' AND is_default = true);

INSERT INTO chore_chart.achievements (name, description, icon, criteria_type, criteria_value, reward_amount, is_default)
SELECT 'Helping Hand', 'Complete 50 total chores', '🤝', 'completion_count', '{"count": 50}', 3.00, true
WHERE NOT EXISTS (SELECT 1 FROM chore_chart.achievements WHERE name = 'Helping Hand' AND is_default = true);

INSERT INTO chore_chart.achievements (name, description, icon, criteria_type, criteria_value, reward_amount, is_default)
SELECT 'Chore Master', 'Complete 100 total chores', '🎖️', 'completion_count', '{"count": 100}', 5.00, true
WHERE NOT EXISTS (SELECT 1 FROM chore_chart.achievements WHERE name = 'Chore Master' AND is_default = true);

INSERT INTO chore_chart.achievements (name, description, icon, criteria_type, criteria_value, reward_amount, is_default)
SELECT 'Superstar', 'Reach S Rank in a single week', '⭐', 'custom', '{"type": "reach_rank", "rank": "S"}', 5.00, true
WHERE NOT EXISTS (SELECT 1 FROM chore_chart.achievements WHERE name = 'Superstar' AND is_default = true);

-- Create privileges table for special rewards parents can grant
CREATE TABLE IF NOT EXISTS chore_chart.privileges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  family_id UUID REFERENCES chore_chart.families(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT DEFAULT '🎁',
  unlock_type TEXT CHECK (unlock_type IN ('achievement', 'manual', 'xp_threshold')),
  unlock_value JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Privileges earned by children
CREATE TABLE IF NOT EXISTS chore_chart.privilege_unlocks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id UUID REFERENCES chore_chart.users(id) ON DELETE CASCADE NOT NULL,
  privilege_id UUID REFERENCES chore_chart.privileges(id) ON DELETE CASCADE NOT NULL,
  unlocked_at TIMESTAMPTZ DEFAULT NOW(),
  used_at TIMESTAMPTZ,
  UNIQUE(child_id, privilege_id)
);

-- Grant permissions
GRANT ALL ON chore_chart.privileges TO anon, authenticated, service_role;
GRANT ALL ON chore_chart.privilege_unlocks TO anon, authenticated, service_role;

-- Enable RLS
ALTER TABLE chore_chart.privileges ENABLE ROW LEVEL SECURITY;
ALTER TABLE chore_chart.privilege_unlocks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all on privileges" ON chore_chart.privileges FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on privilege_unlocks" ON chore_chart.privilege_unlocks FOR ALL USING (true) WITH CHECK (true);
