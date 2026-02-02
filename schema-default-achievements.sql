-- Default Achievements
-- Run this in Supabase SQL Editor

-- Insert default achievements (family_id = NULL means they apply to all families)
INSERT INTO chore_chart.achievements (family_id, name, description, icon, criteria_type, criteria_value, reward_amount, is_default)
SELECT NULL, 'First Quest', 'Complete your first chore', '🎯', 'custom', '{"type": "first_quest"}', 0.50, true
WHERE NOT EXISTS (SELECT 1 FROM chore_chart.achievements WHERE name = 'First Quest' AND is_default = true);

INSERT INTO chore_chart.achievements (family_id, name, description, icon, criteria_type, criteria_value, reward_amount, is_default)
SELECT NULL, 'Getting Started', 'Complete 5 chores', '🚀', 'completion_count', '{"count": 5}', 1.00, true
WHERE NOT EXISTS (SELECT 1 FROM chore_chart.achievements WHERE name = 'Getting Started' AND is_default = true);

INSERT INTO chore_chart.achievements (family_id, name, description, icon, criteria_type, criteria_value, reward_amount, is_default)
SELECT NULL, 'Rising Star', 'Earn 100 total XP', '⭐', 'xp_threshold', '{"xp": 100}', 2.00, true
WHERE NOT EXISTS (SELECT 1 FROM chore_chart.achievements WHERE name = 'Rising Star' AND is_default = true);

INSERT INTO chore_chart.achievements (family_id, name, description, icon, criteria_type, criteria_value, reward_amount, is_default)
SELECT NULL, 'XP Hunter', 'Earn 500 total XP', '💎', 'xp_threshold', '{"xp": 500}', 5.00, true
WHERE NOT EXISTS (SELECT 1 FROM chore_chart.achievements WHERE name = 'XP Hunter' AND is_default = true);

INSERT INTO chore_chart.achievements (family_id, name, description, icon, criteria_type, criteria_value, reward_amount, is_default)
SELECT NULL, 'XP Master', 'Earn 1000 total XP', '👑', 'xp_threshold', '{"xp": 1000}', 10.00, true
WHERE NOT EXISTS (SELECT 1 FROM chore_chart.achievements WHERE name = 'XP Master' AND is_default = true);

INSERT INTO chore_chart.achievements (family_id, name, description, icon, criteria_type, criteria_value, reward_amount, is_default)
SELECT NULL, 'Streak Starter', 'Complete nightly patrol 3 days in a row', '🔥', 'streak', '{"days": 3}', 1.00, true
WHERE NOT EXISTS (SELECT 1 FROM chore_chart.achievements WHERE name = 'Streak Starter' AND is_default = true);

INSERT INTO chore_chart.achievements (family_id, name, description, icon, criteria_type, criteria_value, reward_amount, is_default)
SELECT NULL, 'Week Warrior', 'Complete nightly patrol 5 days in a row', '⚔️', 'streak', '{"days": 5}', 2.00, true
WHERE NOT EXISTS (SELECT 1 FROM chore_chart.achievements WHERE name = 'Week Warrior' AND is_default = true);

INSERT INTO chore_chart.achievements (family_id, name, description, icon, criteria_type, criteria_value, reward_amount, is_default)
SELECT NULL, 'Unstoppable', 'Complete nightly patrol all 7 days', '🏆', 'streak', '{"days": 7}', 5.00, true
WHERE NOT EXISTS (SELECT 1 FROM chore_chart.achievements WHERE name = 'Unstoppable' AND is_default = true);

INSERT INTO chore_chart.achievements (family_id, name, description, icon, criteria_type, criteria_value, reward_amount, is_default)
SELECT NULL, 'Helping Hand', 'Complete 25 total chores', '🤝', 'completion_count', '{"count": 25}', 3.00, true
WHERE NOT EXISTS (SELECT 1 FROM chore_chart.achievements WHERE name = 'Helping Hand' AND is_default = true);

INSERT INTO chore_chart.achievements (family_id, name, description, icon, criteria_type, criteria_value, reward_amount, is_default)
SELECT NULL, 'Chore Champion', 'Complete 50 total chores', '🎖️', 'completion_count', '{"count": 50}', 5.00, true
WHERE NOT EXISTS (SELECT 1 FROM chore_chart.achievements WHERE name = 'Chore Champion' AND is_default = true);

INSERT INTO chore_chart.achievements (family_id, name, description, icon, criteria_type, criteria_value, reward_amount, is_default)
SELECT NULL, 'Superstar', 'Reach S Rank in a single week', '🌟', 'custom', '{"type": "reach_rank", "rank": "S"}', 5.00, true
WHERE NOT EXISTS (SELECT 1 FROM chore_chart.achievements WHERE name = 'Superstar' AND is_default = true);

-- Make sure achievements are visible to all families by allowing NULL family_id or matching family
-- Update the getAchievements query may need to handle this
