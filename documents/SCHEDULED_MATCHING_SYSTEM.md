# Scheduled Matching System

This document describes the new scheduled matching system for Hearty (BlindDate), which replaces the real-time matching with a daily batch processing system that reveals matches at scheduled times.

## Overview

The scheduled matching system creates matches through automated batch processing and reveals them at specific times (noon KST daily), creating anticipation and making matches feel more special.

### Key Features

- **Daily Batch Processing**: Matches are created automatically using a sophisticated algorithm
- **Scheduled Reveals**: Matches are revealed at noon KST (12:00 PM Korea time)
- **24-Hour Match Lifecycle**: Matches expire at 11:59 AM the next day
- **Mutual Like Detection**: System tracks when both users like each other
- **Automated Cleanup**: Expired matches are automatically removed

## System Architecture

### Database Schema

#### Core Tables

1. **`blinddate_scheduled_matches`**
   - Stores matches created by batch processing
   - Tracks reveal times and expiration
   - Includes status tracking (pending, revealed, expired, mutual_like)

2. **`blinddate_daily_match_processing`**
   - Logs each batch processing run
   - Tracks success/failure and statistics
   - Provides audit trail for debugging

3. **`blinddate_user_match_preferences`**
   - User preferences for matching (age range, distance, etc.)
   - Controls whether user participates in matching

4. **`blinddate_match_interactions`**
   - Tracks user actions on matches (viewed, liked, passed, chatted)
   - Prevents duplicate actions
   - Enables mutual like detection

### Edge Functions

#### 1. Daily Batch Matching (`daily-batch-matching`)
- **Schedule**: Runs at 11:30 AM KST (2:30 AM UTC) daily
- **Purpose**: Creates matches for the day
- **Algorithm**:
  - Fetches all approved, active users
  - Groups by gender for opposite-sex matching
  - Applies age and preference filters
  - Creates randomized matches ensuring no duplicates
  - Sets reveal time to noon KST, expiration to next day 11:59 AM

#### 2. Match Reveal (`reveal-matches`)
- **Schedule**: Runs every hour
- **Purpose**: Reveals pending matches and cleans up expired ones
- **Functions**:
  - Updates pending matches to revealed when reveal time arrives
  - Removes expired matches from database
  - Sends push notifications (when implemented)

### Client-Side Components

#### 1. ScheduledMatchingService
- Manages scheduled matches data and state
- Provides countdown timers and reveal time calculations
- Handles match interactions (like, pass, chat)
- Tracks mutual likes automatically

#### 2. ScheduledHomeScreen
- Main UI for viewing today's matches
- Shows countdown until next reveal
- Displays different states:
  - Loading matches
  - Countdown to reveal time
  - Revealed matches ready for interaction
  - No matches available
  - Mutual matches with chat options

#### 3. ScheduledMatchCard
- Individual match display component
- Shows user photos, profile info, interests
- Provides like/pass action buttons
- Highlights mutual matches with special UI

## Daily Flow

### Timeline (Korea Standard Time)

1. **11:30 AM**: Batch matching algorithm runs
   - Creates matches for eligible users
   - Sets reveal time to 12:00 PM same day
   - Sets expiration to 11:59 AM next day

2. **12:00 PM**: Matches revealed to users
   - Users can view their daily match
   - Like/pass actions become available
   - Countdown shows time until expiration

3. **Throughout the day**: User interactions
   - Users view and interact with matches
   - System tracks likes and passes
   - Mutual likes are detected automatically

4. **11:59 PM**: Day ends
   - Matches remain available for interaction
   - New batch processing begins preparation

5. **11:59 AM Next Day**: Matches expire
   - Unexpired matches are cleaned up
   - New matches will be revealed at noon

## Implementation Guide

### 1. Database Setup

```sql
-- Run the migration files
\i database_migrations/001_scheduled_matching.sql
\i database_migrations/002_cron_jobs.sql
```

### 2. Enable Required Extensions

```sql
-- Enable pg_cron for scheduled jobs
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Enable http extension for calling Edge Functions
CREATE EXTENSION IF NOT EXISTS http;
```

### 3. Deploy Edge Functions

```bash
# Deploy batch matching function
supabase functions deploy daily-batch-matching

# Deploy reveal function
supabase functions deploy reveal-matches
```

### 4. Configure Cron Jobs

Update the cron job URLs in `002_cron_jobs.sql` with your actual Supabase project details:

```sql
-- Replace placeholders
YOUR_SUPABASE_URL -> https://your-project.supabase.co
YOUR_SERVICE_ROLE_KEY -> your_actual_service_role_key
```

### 5. Update Flutter App

The Flutter app has been updated to use the new system:
- `ScheduledMatchingService` replaces old matching logic
- `ScheduledHomeScreen` shows new UI with countdown and match cards
- Routes updated to use scheduled home screen

## Testing

### Manual Testing Functions

```sql
-- Test batch matching
SELECT trigger_batch_matching();

-- Test reveal and cleanup
SELECT run_daily_maintenance();

-- Check processing logs
SELECT * FROM blinddate_daily_match_processing ORDER BY created_at DESC;

-- View today's matches for a user
SELECT * FROM blinddate_scheduled_matches
WHERE (user1_id = 'user-uuid' OR user2_id = 'user-uuid')
AND match_date = CURRENT_DATE;
```

### Testing Edge Functions

```bash
# Test batch matching function
curl -X POST 'https://your-project.supabase.co/functions/v1/daily-batch-matching' \
  -H 'Authorization: Bearer YOUR_SERVICE_ROLE_KEY'

# Test reveal function
curl -X POST 'https://your-project.supabase.co/functions/v1/reveal-matches' \
  -H 'Authorization: Bearer YOUR_SERVICE_ROLE_KEY'
```

## Monitoring

### Key Metrics to Monitor

1. **Daily Batch Success Rate**
   ```sql
   SELECT
     process_date,
     status,
     total_eligible_users,
     total_matches_created,
     error_message
   FROM blinddate_daily_match_processing
   ORDER BY process_date DESC;
   ```

2. **Match Reveal Statistics**
   ```sql
   SELECT
     COUNT(*) as total_matches,
     SUM(CASE WHEN status = 'revealed' THEN 1 ELSE 0 END) as revealed_matches,
     SUM(CASE WHEN status = 'mutual_like' THEN 1 ELSE 0 END) as mutual_likes
   FROM blinddate_scheduled_matches
   WHERE match_date = CURRENT_DATE;
   ```

3. **User Engagement**
   ```sql
   SELECT
     action,
     COUNT(*) as count
   FROM blinddate_match_interactions mi
   JOIN blinddate_scheduled_matches sm ON mi.scheduled_match_id = sm.id
   WHERE sm.match_date = CURRENT_DATE
   GROUP BY action;
   ```

## Migration from Old System

### Differences from Previous System

| Old System | New System |
|------------|------------|
| Real-time matching | Scheduled batch matching |
| Immediate recommendations | Daily reveals at noon |
| Always available | 24-hour match lifecycle |
| Manual refresh needed | Automatic processing |
| No match persistence | Matches persist until expiration |

### Data Migration

The new system runs alongside the old system. No data migration is required as they use different tables:

- Old: `blinddate_daily_recommendations`, `blinddate_user_actions`
- New: `blinddate_scheduled_matches`, `blinddate_match_interactions`

## Troubleshooting

### Common Issues

1. **Matches not being created**
   - Check `blinddate_daily_match_processing` for errors
   - Verify eligible users exist with correct approval status
   - Ensure Edge Function deployment is successful

2. **Matches not revealing**
   - Check system time vs KST conversion
   - Verify `reveal-matches` Edge Function is running
   - Check cron job configuration

3. **Countdown showing incorrect time**
   - Verify timezone handling in client code
   - Check server time synchronization

### Debug Commands

```sql
-- Check current system time
SELECT NOW(), NOW() AT TIME ZONE 'Asia/Seoul' as seoul_time;

-- View pending matches that should be revealed
SELECT * FROM blinddate_scheduled_matches
WHERE status = 'pending' AND reveal_time <= NOW();

-- Check cron job status
SELECT * FROM cron.job;
```

## Future Enhancements

1. **Push Notifications**: Send notifications when matches are revealed
2. **Match Quality Scoring**: Improve algorithm with compatibility scoring
3. **Geographic Matching**: Add location-based matching preferences
4. **Premium Features**: Special matching options for premium users
5. **Analytics Dashboard**: Admin interface for monitoring system health
6. **A/B Testing**: Test different reveal times and match quantities

## Security Considerations

- All database functions use `SECURITY DEFINER` for proper permissions
- RLS policies protect user data access
- Service role key must be kept secure
- Edge Functions validate authentication
- User actions are tracked for audit purposes

## Performance Considerations

- Indexes on key tables for fast queries
- Batch processing handles large user bases efficiently
- Cleanup functions prevent database bloat
- Client-side caching reduces API calls
- Efficient data structures for real-time countdown updates