-- Move Chore Chart tables to dedicated schema
-- Run this in Supabase SQL Editor

-- ============================================
-- CREATE SCHEMA
-- ============================================

CREATE SCHEMA IF NOT EXISTS chore_chart;

-- ============================================
-- MOVE TABLES TO NEW SCHEMA
-- ============================================

-- Move tables (order matters due to foreign keys - move referenced tables first)
ALTER TABLE IF EXISTS public.families SET SCHEMA chore_chart;
ALTER TABLE IF EXISTS public.users SET SCHEMA chore_chart;
ALTER TABLE IF EXISTS public.chore_templates SET SCHEMA chore_chart;
ALTER TABLE IF EXISTS public.chore_assignments SET SCHEMA chore_chart;
ALTER TABLE IF EXISTS public.chore_completions SET SCHEMA chore_chart;
ALTER TABLE IF EXISTS public.reminders SET SCHEMA chore_chart;
ALTER TABLE IF EXISTS public.weekly_earnings SET SCHEMA chore_chart;
ALTER TABLE IF EXISTS public.achievements SET SCHEMA chore_chart;
ALTER TABLE IF EXISTS public.achievement_unlocks SET SCHEMA chore_chart;

-- ============================================
-- EXPOSE SCHEMA TO API (PostgREST)
-- ============================================

-- Grant usage on schema to roles
GRANT USAGE ON SCHEMA chore_chart TO anon;
GRANT USAGE ON SCHEMA chore_chart TO authenticated;
GRANT USAGE ON SCHEMA chore_chart TO service_role;

-- Grant table permissions
GRANT ALL ON ALL TABLES IN SCHEMA chore_chart TO anon;
GRANT ALL ON ALL TABLES IN SCHEMA chore_chart TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA chore_chart TO service_role;

-- Grant sequence permissions (for auto-generated IDs)
GRANT ALL ON ALL SEQUENCES IN SCHEMA chore_chart TO anon;
GRANT ALL ON ALL SEQUENCES IN SCHEMA chore_chart TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA chore_chart TO service_role;

-- ============================================
-- UPDATE SUPABASE API CONFIG
-- ============================================

-- Add chore_chart to the exposed schemas
-- NOTE: You also need to update this in Supabase Dashboard:
-- Settings > API > Exposed schemas > Add "chore_chart"

-- Alternatively, notify PostgREST to include this schema
NOTIFY pgrst, 'reload config';

-- ============================================
-- MOVE FUNCTIONS TO NEW SCHEMA
-- ============================================

-- Recreate functions in the new schema
CREATE OR REPLACE FUNCTION chore_chart.get_week_start(d DATE DEFAULT CURRENT_DATE)
RETURNS DATE AS $$
BEGIN
  RETURN d - EXTRACT(DOW FROM d)::INT;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION chore_chart.generate_link_code()
RETURNS TEXT AS $$
BEGIN
  RETURN LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION chore_chart.calculate_rank(xp INT)
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

CREATE OR REPLACE FUNCTION chore_chart.calculate_base_pay(rank TEXT)
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

-- Drop old functions from public schema (optional)
DROP FUNCTION IF EXISTS public.get_week_start(DATE);
DROP FUNCTION IF EXISTS public.generate_link_code();
DROP FUNCTION IF EXISTS public.calculate_rank(INT);
DROP FUNCTION IF EXISTS public.calculate_base_pay(TEXT);

-- ============================================
-- VERIFICATION
-- ============================================

-- Run this to verify tables moved successfully:
-- SELECT table_schema, table_name
-- FROM information_schema.tables
-- WHERE table_schema = 'chore_chart';
