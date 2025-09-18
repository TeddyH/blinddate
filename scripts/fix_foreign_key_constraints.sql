-- 외래 키 제약 조건 수정
-- 현재: blinddate_scheduled_matches -> users (존재하지 않음)
-- 수정: blinddate_scheduled_matches -> blinddate_users

-- 먼저 기존 외래 키 제약 조건 삭제
ALTER TABLE blinddate_scheduled_matches
DROP CONSTRAINT IF EXISTS blinddate_scheduled_matches_user1_id_fkey;

ALTER TABLE blinddate_scheduled_matches
DROP CONSTRAINT IF EXISTS blinddate_scheduled_matches_user2_id_fkey;

-- 올바른 외래 키 제약 조건 추가
ALTER TABLE blinddate_scheduled_matches
ADD CONSTRAINT blinddate_scheduled_matches_user1_id_fkey
FOREIGN KEY (user1_id) REFERENCES blinddate_users(id) ON DELETE CASCADE;

ALTER TABLE blinddate_scheduled_matches
ADD CONSTRAINT blinddate_scheduled_matches_user2_id_fkey
FOREIGN KEY (user2_id) REFERENCES blinddate_users(id) ON DELETE CASCADE;

-- 다른 테이블들도 확인하고 수정
-- match_interactions 테이블
ALTER TABLE blinddate_match_interactions
DROP CONSTRAINT IF EXISTS blinddate_match_interactions_user_id_fkey;

ALTER TABLE blinddate_match_interactions
ADD CONSTRAINT blinddate_match_interactions_user_id_fkey
FOREIGN KEY (user_id) REFERENCES blinddate_users(id) ON DELETE CASCADE;

-- messages 테이블
ALTER TABLE blinddate_messages
DROP CONSTRAINT IF EXISTS blinddate_messages_sender_id_fkey;

ALTER TABLE blinddate_messages
ADD CONSTRAINT blinddate_messages_sender_id_fkey
FOREIGN KEY (sender_id) REFERENCES blinddate_users(id) ON DELETE CASCADE;

-- daily_recommendations 테이블
ALTER TABLE blinddate_daily_recommendations
DROP CONSTRAINT IF EXISTS blinddate_daily_recommendations_user_id_fkey;

ALTER TABLE blinddate_daily_recommendations
DROP CONSTRAINT IF EXISTS blinddate_daily_recommendations_recommended_user_id_fkey;

ALTER TABLE blinddate_daily_recommendations
ADD CONSTRAINT blinddate_daily_recommendations_user_id_fkey
FOREIGN KEY (user_id) REFERENCES blinddate_users(id) ON DELETE CASCADE;

ALTER TABLE blinddate_daily_recommendations
ADD CONSTRAINT blinddate_daily_recommendations_recommended_user_id_fkey
FOREIGN KEY (recommended_user_id) REFERENCES blinddate_users(id) ON DELETE CASCADE;

-- admin_actions 테이블
ALTER TABLE blinddate_admin_actions
DROP CONSTRAINT IF EXISTS blinddate_admin_actions_admin_id_fkey;

ALTER TABLE blinddate_admin_actions
DROP CONSTRAINT IF EXISTS blinddate_admin_actions_target_user_id_fkey;

ALTER TABLE blinddate_admin_actions
ADD CONSTRAINT blinddate_admin_actions_admin_id_fkey
FOREIGN KEY (admin_id) REFERENCES blinddate_users(id) ON DELETE CASCADE;

ALTER TABLE blinddate_admin_actions
ADD CONSTRAINT blinddate_admin_actions_target_user_id_fkey
FOREIGN KEY (target_user_id) REFERENCES blinddate_users(id) ON DELETE CASCADE;

-- user_actions 테이블
ALTER TABLE blinddate_user_actions
DROP CONSTRAINT IF EXISTS blinddate_user_actions_user_id_fkey;

ALTER TABLE blinddate_user_actions
DROP CONSTRAINT IF EXISTS blinddate_user_actions_target_user_id_fkey;

ALTER TABLE blinddate_user_actions
ADD CONSTRAINT blinddate_user_actions_user_id_fkey
FOREIGN KEY (user_id) REFERENCES blinddate_users(id) ON DELETE CASCADE;

ALTER TABLE blinddate_user_actions
ADD CONSTRAINT blinddate_user_actions_target_user_id_fkey
FOREIGN KEY (target_user_id) REFERENCES blinddate_users(id) ON DELETE CASCADE;