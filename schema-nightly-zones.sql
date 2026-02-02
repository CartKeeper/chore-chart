-- Nightly Zones Table
-- Run this in Supabase SQL Editor

-- Create nightly_zones table (family-wide zone configuration)
CREATE TABLE IF NOT EXISTS chore_chart.nightly_zones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  family_id UUID REFERENCES chore_chart.families(id) ON DELETE CASCADE NOT NULL,
  zone_key TEXT NOT NULL,
  name TEXT NOT NULL,
  icon TEXT DEFAULT '🧹',
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(family_id, zone_key)
);

-- Create nightly_completions table (tracks which zones each child completed each day)
CREATE TABLE IF NOT EXISTS chore_chart.nightly_completions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id UUID REFERENCES chore_chart.users(id) ON DELETE CASCADE NOT NULL,
  zone_id UUID REFERENCES chore_chart.nightly_zones(id) ON DELETE CASCADE NOT NULL,
  week_start DATE NOT NULL,
  day_of_week INT NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
  completed_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(child_id, zone_id, week_start, day_of_week)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_nightly_zones_family ON chore_chart.nightly_zones(family_id);
CREATE INDEX IF NOT EXISTS idx_nightly_completions_child ON chore_chart.nightly_completions(child_id);
CREATE INDEX IF NOT EXISTS idx_nightly_completions_week ON chore_chart.nightly_completions(week_start);

-- Grant permissions
GRANT ALL ON chore_chart.nightly_zones TO anon, authenticated, service_role;
GRANT ALL ON chore_chart.nightly_completions TO anon, authenticated, service_role;

-- Enable RLS
ALTER TABLE chore_chart.nightly_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE chore_chart.nightly_completions ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Allow all on nightly_zones" ON chore_chart.nightly_zones FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on nightly_completions" ON chore_chart.nightly_completions FOR ALL USING (true) WITH CHECK (true);
