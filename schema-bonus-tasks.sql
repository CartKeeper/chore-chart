-- Bonus Tasks (Money Makers) Table
-- Run this in Supabase SQL Editor

-- Create bonus_tasks table
CREATE TABLE IF NOT EXISTS chore_chart.bonus_tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  family_id UUID REFERENCES chore_chart.families(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT DEFAULT '💵',
  amount DECIMAL(10,2) DEFAULT 0,
  xp_value INT DEFAULT 10,
  is_active BOOLEAN DEFAULT TRUE,
  created_by UUID REFERENCES chore_chart.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create bonus_task_completions table
CREATE TABLE IF NOT EXISTS chore_chart.bonus_task_completions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  bonus_task_id UUID REFERENCES chore_chart.bonus_tasks(id) ON DELETE CASCADE NOT NULL,
  child_id UUID REFERENCES chore_chart.users(id) ON DELETE CASCADE NOT NULL,
  week_start DATE NOT NULL,
  completed_at TIMESTAMPTZ DEFAULT NOW(),
  xp_earned INT DEFAULT 0,
  amount_earned DECIMAL(10,2) DEFAULT 0,
  UNIQUE(bonus_task_id, child_id, week_start)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_bonus_tasks_family ON chore_chart.bonus_tasks(family_id);
CREATE INDEX IF NOT EXISTS idx_bonus_task_completions_child ON chore_chart.bonus_task_completions(child_id);
CREATE INDEX IF NOT EXISTS idx_bonus_task_completions_week ON chore_chart.bonus_task_completions(week_start);

-- Grant permissions
GRANT ALL ON chore_chart.bonus_tasks TO anon, authenticated, service_role;
GRANT ALL ON chore_chart.bonus_task_completions TO anon, authenticated, service_role;

-- Enable RLS
ALTER TABLE chore_chart.bonus_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE chore_chart.bonus_task_completions ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Allow all on bonus_tasks" ON chore_chart.bonus_tasks FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on bonus_task_completions" ON chore_chart.bonus_task_completions FOR ALL USING (true) WITH CHECK (true);
