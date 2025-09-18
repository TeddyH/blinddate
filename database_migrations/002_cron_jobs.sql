-- Cron job setup for scheduled matching system
-- These should be run with pg_cron extension enabled

-- 1. Daily batch matching job - runs at 11:30 AM KST (2:30 AM UTC)
-- This creates matches for the day that will be revealed at noon
SELECT cron.schedule(
  'daily-batch-matching',
  '30 2 * * *',  -- 2:30 AM UTC = 11:30 AM KST
  $$
  SELECT net.http_post(
    url := 'YOUR_SUPABASE_URL/functions/v1/daily-batch-matching',
    headers := '{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb,
    body := '{}'::jsonb
  );
  $$
);

-- 2. Match reveal job - runs every hour to check for matches ready to be revealed
SELECT cron.schedule(
  'reveal-matches',
  '0 * * * *',  -- Every hour
  $$
  SELECT net.http_post(
    url := 'YOUR_SUPABASE_URL/functions/v1/reveal-matches',
    headers := '{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb,
    body := '{}'::jsonb
  );
  $$
);

-- 3. Cleanup expired matches - runs daily at midnight KST (3 PM UTC previous day)
SELECT cron.schedule(
  'cleanup-expired-matches',
  '0 15 * * *',  -- 3 PM UTC = Midnight KST next day
  $$
  SELECT cleanup_expired_matches();
  $$
);

-- 4. Alternative manual cleanup function that can be called directly
CREATE OR REPLACE FUNCTION run_daily_maintenance()
RETURNS jsonb AS $$
DECLARE
  revealed_count INTEGER;
  cleaned_count INTEGER;
  result jsonb;
BEGIN
  -- Reveal any pending matches that should be revealed
  SELECT reveal_scheduled_matches() INTO revealed_count;

  -- Clean up expired matches
  SELECT cleanup_expired_matches() INTO cleaned_count;

  -- Return results
  result := jsonb_build_object(
    'revealed_matches', revealed_count,
    'cleaned_matches', cleaned_count,
    'timestamp', NOW()
  );

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Function to trigger batch matching manually (for testing)
CREATE OR REPLACE FUNCTION trigger_batch_matching()
RETURNS jsonb AS $$
BEGIN
  -- This would typically call the Edge Function
  -- For now, return a placeholder response
  RETURN jsonb_build_object(
    'message', 'Batch matching should be triggered via Edge Function',
    'function_url', 'YOUR_SUPABASE_URL/functions/v1/daily-batch-matching',
    'timestamp', NOW()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comments for setup instructions:
/*
SETUP INSTRUCTIONS:

1. Enable pg_cron extension in your Supabase project:
   - Go to Database > Extensions in Supabase dashboard
   - Enable the "pg_cron" extension

2. Update the cron job URLs:
   - Replace 'YOUR_SUPABASE_URL' with your actual Supabase project URL
   - Replace 'YOUR_SERVICE_ROLE_KEY' with your service role key

3. Deploy the Edge Functions:
   - Run: supabase functions deploy daily-batch-matching
   - Run: supabase functions deploy reveal-matches

4. Test the system:
   - Call SELECT trigger_batch_matching(); to test batch matching
   - Call SELECT run_daily_maintenance(); to test reveal and cleanup

5. Monitor the cron jobs:
   - Check cron.job table for job status
   - Check blinddate_daily_match_processing table for batch results

SECURITY NOTES:
- All functions use SECURITY DEFINER to run with elevated privileges
- RLS policies protect user data access
- Service role key should be kept secure and not exposed in client code
*/