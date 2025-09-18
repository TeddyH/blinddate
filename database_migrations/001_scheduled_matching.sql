-- Database schema for scheduled matching system
-- This implements daily batch matching with scheduled reveals at noon

-- 1. Scheduled Matches Table
-- Stores matches created by batch processing with reveal times
CREATE TABLE IF NOT EXISTS blinddate_scheduled_matches (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user1_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  user2_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  match_date DATE NOT NULL, -- The date this match was created for
  reveal_time TIMESTAMPTZ NOT NULL, -- When this match should be revealed (noon KST)
  revealed_at TIMESTAMPTZ NULL, -- When the match was actually revealed to users
  expires_at TIMESTAMPTZ NOT NULL, -- When this match expires (next day 11:59am)
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'revealed', 'expired', 'mutual_like')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Ensure no duplicate matches for the same date
  UNIQUE(user1_id, user2_id, match_date),
  -- Ensure user1_id < user2_id to avoid duplicate pairs
  CHECK (user1_id < user2_id)
);

-- 2. Daily Match Processing Log
-- Track batch processing runs and their results
CREATE TABLE IF NOT EXISTS blinddate_daily_match_processing (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  process_date DATE NOT NULL UNIQUE,
  started_at TIMESTAMPTZ NOT NULL,
  completed_at TIMESTAMPTZ NULL,
  total_eligible_users INTEGER DEFAULT 0,
  total_matches_created INTEGER DEFAULT 0,
  status VARCHAR(20) DEFAULT 'running' CHECK (status IN ('running', 'completed', 'failed')),
  error_message TEXT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. User Match Preferences
-- Store user preferences for matching (can be expanded later)
CREATE TABLE IF NOT EXISTS blinddate_user_match_preferences (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  min_age INTEGER DEFAULT 18,
  max_age INTEGER DEFAULT 99,
  preferred_distance_km INTEGER DEFAULT 50,
  notify_on_match BOOLEAN DEFAULT true,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Match Interactions
-- Track how users interact with their revealed matches
CREATE TABLE IF NOT EXISTS blinddate_match_interactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  scheduled_match_id UUID REFERENCES blinddate_scheduled_matches(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  action VARCHAR(20) NOT NULL CHECK (action IN ('viewed', 'liked', 'passed', 'chatted')),
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Prevent duplicate actions for same match by same user
  UNIQUE(scheduled_match_id, user_id, action)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_scheduled_matches_reveal_time ON blinddate_scheduled_matches(reveal_time) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_scheduled_matches_expires_at ON blinddate_scheduled_matches(expires_at) WHERE status IN ('pending', 'revealed');
CREATE INDEX IF NOT EXISTS idx_scheduled_matches_user1 ON blinddate_scheduled_matches(user1_id);
CREATE INDEX IF NOT EXISTS idx_scheduled_matches_user2 ON blinddate_scheduled_matches(user2_id);
CREATE INDEX IF NOT EXISTS idx_scheduled_matches_date ON blinddate_scheduled_matches(match_date);
CREATE INDEX IF NOT EXISTS idx_match_interactions_user ON blinddate_match_interactions(user_id);
CREATE INDEX IF NOT EXISTS idx_match_interactions_match ON blinddate_match_interactions(scheduled_match_id);

-- RLS Policies

-- Users can only see their own scheduled matches
ALTER TABLE blinddate_scheduled_matches ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own scheduled matches" ON blinddate_scheduled_matches
  FOR SELECT USING (
    auth.uid() = user1_id OR auth.uid() = user2_id
  );

-- Users can interact with their own matches
ALTER TABLE blinddate_match_interactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own match interactions" ON blinddate_match_interactions
  FOR ALL USING (auth.uid() = user_id);

-- Users can view and update their own preferences
ALTER TABLE blinddate_user_match_preferences ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own match preferences" ON blinddate_user_match_preferences
  FOR ALL USING (auth.uid() = user_id);

-- Only service role can read processing logs (for admin/monitoring)
ALTER TABLE blinddate_daily_match_processing ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Service role can manage processing logs" ON blinddate_daily_match_processing
  FOR ALL USING (auth.role() = 'service_role');

-- Functions

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers to automatically update updated_at
CREATE TRIGGER update_scheduled_matches_updated_at
  BEFORE UPDATE ON blinddate_scheduled_matches
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_match_preferences_updated_at
  BEFORE UPDATE ON blinddate_user_match_preferences
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to clean up expired matches (to be called by cron)
CREATE OR REPLACE FUNCTION cleanup_expired_matches()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM blinddate_scheduled_matches
  WHERE expires_at < NOW() AND status IN ('pending', 'revealed');

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to reveal matches at scheduled time
CREATE OR REPLACE FUNCTION reveal_scheduled_matches()
RETURNS INTEGER AS $$
DECLARE
  revealed_count INTEGER;
BEGIN
  UPDATE blinddate_scheduled_matches
  SET
    status = 'revealed',
    revealed_at = NOW()
  WHERE
    status = 'pending'
    AND reveal_time <= NOW();

  GET DIAGNOSTICS revealed_count = ROW_COUNT;
  RETURN revealed_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;