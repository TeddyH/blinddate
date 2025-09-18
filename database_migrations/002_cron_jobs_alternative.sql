-- Alternative cron job setup for scheduled matching system
-- Since pg_cron may not be available in all Supabase instances,
-- this file provides alternative approaches using system cron + Edge Functions

-- 1. Functions for manual testing and maintenance
-- These can be called directly from your application or via system cron

-- Function to manually trigger batch matching (calls Edge Function)
CREATE OR REPLACE FUNCTION trigger_batch_matching_manual()
RETURNS jsonb AS $$
BEGIN
  -- This function serves as a placeholder/documentation
  -- The actual batch matching is handled by the Edge Function
  -- Call via HTTP: POST /functions/v1/daily-batch-matching

  RETURN jsonb_build_object(
    'message', 'Use Edge Function for batch matching',
    'endpoint', '/functions/v1/daily-batch-matching',
    'method', 'POST',
    'headers', jsonb_build_object('Authorization', 'Bearer SERVICE_ROLE_KEY'),
    'timestamp', NOW()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to manually trigger reveal and cleanup (calls Edge Function)
CREATE OR REPLACE FUNCTION trigger_reveal_cleanup_manual()
RETURNS jsonb AS $$
BEGIN
  -- This function serves as a placeholder/documentation
  -- The actual reveal and cleanup is handled by the Edge Function
  -- Call via HTTP: POST /functions/v1/reveal-matches

  RETURN jsonb_build_object(
    'message', 'Use Edge Function for reveal and cleanup',
    'endpoint', '/functions/v1/reveal-matches',
    'method', 'POST',
    'headers', jsonb_build_object('Authorization', 'Bearer SERVICE_ROLE_KEY'),
    'timestamp', NOW()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get current system status for monitoring
CREATE OR REPLACE FUNCTION get_matching_system_status()
RETURNS jsonb AS $$
DECLARE
  today_date DATE := CURRENT_DATE;
  processing_status jsonb;
  match_stats jsonb;
  result jsonb;
BEGIN
  -- Get today's processing status
  SELECT jsonb_build_object(
    'process_date', process_date,
    'status', status,
    'total_eligible_users', total_eligible_users,
    'total_matches_created', total_matches_created,
    'started_at', started_at,
    'completed_at', completed_at,
    'error_message', error_message
  ) INTO processing_status
  FROM blinddate_daily_match_processing
  WHERE process_date = today_date
  ORDER BY created_at DESC
  LIMIT 1;

  -- Get today's match statistics
  SELECT jsonb_build_object(
    'total_matches', COUNT(*),
    'pending_matches', COUNT(*) FILTER (WHERE status = 'pending'),
    'revealed_matches', COUNT(*) FILTER (WHERE status = 'revealed'),
    'mutual_likes', COUNT(*) FILTER (WHERE status = 'mutual_like'),
    'expired_matches', COUNT(*) FILTER (WHERE status = 'expired')
  ) INTO match_stats
  FROM blinddate_scheduled_matches
  WHERE match_date = today_date;

  -- Combine results
  result := jsonb_build_object(
    'date', today_date,
    'server_time', NOW(),
    'korea_time', NOW() AT TIME ZONE 'Asia/Seoul',
    'processing_status', COALESCE(processing_status, '{"message": "No processing record found for today"}'::jsonb),
    'match_statistics', COALESCE(match_stats, '{"total_matches": 0}'::jsonb)
  );

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check what matches should be revealed now
CREATE OR REPLACE FUNCTION check_pending_reveals()
RETURNS jsonb AS $$
DECLARE
  current_time TIMESTAMPTZ := NOW();
  pending_count INTEGER;
  ready_count INTEGER;
  result jsonb;
BEGIN
  -- Count pending matches
  SELECT COUNT(*) INTO pending_count
  FROM blinddate_scheduled_matches
  WHERE status = 'pending';

  -- Count matches ready to be revealed
  SELECT COUNT(*) INTO ready_count
  FROM blinddate_scheduled_matches
  WHERE status = 'pending'
  AND reveal_time <= current_time;

  result := jsonb_build_object(
    'current_time', current_time,
    'korea_time', current_time AT TIME ZONE 'Asia/Seoul',
    'total_pending_matches', pending_count,
    'ready_to_reveal', ready_count,
    'action_needed', CASE WHEN ready_count > 0 THEN 'Call reveal-matches endpoint' ELSE 'No action needed' END
  );

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions to authenticated users for monitoring functions
GRANT EXECUTE ON FUNCTION get_matching_system_status() TO authenticated;
GRANT EXECUTE ON FUNCTION check_pending_reveals() TO authenticated;

-- System cron setup instructions (to be run on your server)
/*
SYSTEM CRON SETUP INSTRUCTIONS:

1. Create environment file on your server:
   /home/honghyungseok/hearty-scheduler/.env

   Contents:
   SUPABASE_URL="https://your-project.supabase.co"
   SERVICE_ROLE_KEY="your_service_role_key_here"

2. Add these cron jobs to your server crontab:

# Hearty App Production Schedule
# Daily batch matching at 11:30 AM KST (2:30 AM UTC)
30 2 * * * /home/honghyungseok/hearty-scheduler/hearty_batch_matching.sh >> /data/log/hearty/batch_matching.log 2>&1

# Match reveal and cleanup every hour
0 * * * * /home/honghyungseok/hearty-scheduler/hearty_reveal_matches.sh >> /data/log/hearty/reveal_matches.log 2>&1

# Optional: Daily status check at 1 PM KST (4 AM UTC)
0 4 * * * /home/honghyungseok/hearty-scheduler/hearty_status_check.sh >> /data/log/hearty/status_check.log 2>&1

3. Test the setup:
   - Run the test script: /home/honghyungseok/hearty-scheduler/hearty_test_schedule.sh
   - Check logs in: /data/log/hearty/
   - Monitor with: SELECT get_matching_system_status();

4. Monitor the system:
   - Database function: SELECT get_matching_system_status();
   - Check reveals: SELECT check_pending_reveals();
   - View logs: tail -f /data/log/hearty/*.log

ALTERNATIVE FOR SUPABASE HOSTED SOLUTIONS:

If you're using Supabase hosted instance and want to avoid system cron:

1. Use Supabase Edge Functions with Deno cron (if available)
2. Use external cron services (like GitHub Actions, Vercel Cron, etc.)
3. Use cloud provider cron (AWS EventBridge, GCP Cloud Scheduler)
4. Use a monitoring service that can trigger webhooks

Example GitHub Actions workflow:
```yaml
name: Hearty Daily Matching
on:
  schedule:
    - cron: '30 2 * * *'  # 11:30 AM KST
jobs:
  batch-matching:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger Batch Matching
        run: |
          curl -X POST \
            -H "Authorization: Bearer ${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}" \
            "${{ secrets.SUPABASE_URL }}/functions/v1/daily-batch-matching"
```
*/