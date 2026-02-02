-- Push Notifications Setup
-- Run this in Supabase SQL Editor

-- Enable the pg_cron extension (if not already enabled)
-- Go to Database > Extensions in Supabase Dashboard and enable pg_cron

-- Enable the pg_net extension for HTTP requests
-- Go to Database > Extensions in Supabase Dashboard and enable pg_net

-- Schedule the send-reminders function to run every minute
-- Note: You need to replace YOUR_PROJECT_REF with your actual Supabase project reference
-- and YOUR_ANON_KEY with your actual anon key

-- First, make sure pg_cron is enabled, then run:

SELECT cron.schedule(
  'send-reminders-every-minute',  -- job name
  '* * * * *',                     -- every minute
  $$
  SELECT net.http_post(
    url := 'https://anksgmvundwmggysztjh.supabase.co/functions/v1/send-reminders',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFua3NnbXZ1bmR3bWdneXN6dGpoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg4ODQ2NjAsImV4cCI6MjA4NDQ2MDY2MH0.opmqicid41-6AY1kQZBHflELZy6ZDKEsRi1fwehGbhA'
    ),
    body := '{}'::jsonb
  );
  $$
);

-- To view scheduled jobs:
-- SELECT * FROM cron.job;

-- To remove the job if needed:
-- SELECT cron.unschedule('send-reminders-every-minute');
