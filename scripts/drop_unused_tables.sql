-- 불필요한 테이블들 제거 SQL 스크립트
-- 실행 전 중요: 데이터 백업을 권장합니다!

-- 1. blinddate_user_profiles 테이블 제거
-- (사용자 상세 프로필 - blinddate_users에 모든 정보 통합)
DROP TABLE IF EXISTS blinddate_user_profiles CASCADE;

-- 2. blinddate_user_match_preferences 테이블 제거
-- (매칭 설정 - 100% 랜덤 매칭으로 변경)
DROP TABLE IF EXISTS blinddate_user_match_preferences CASCADE;

-- 3. blinddate_daily_recommendations 테이블 제거
-- (레거시 추천 시스템 - scheduled_matches로 대체)
DROP TABLE IF EXISTS blinddate_daily_recommendations CASCADE;

-- 4. blinddate_admin_actions 테이블 제거
-- (관리자 액션 감사 - 감사 프로세스 없음)
DROP TABLE IF EXISTS blinddate_admin_actions CASCADE;

-- 결과 확인: 남은 테이블들 목록 조회
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name LIKE 'blinddate_%'
ORDER BY table_name;

-- 예상 결과 (남아있어야 할 테이블들):
-- blinddate_daily_match_processing
-- blinddate_match_interactions
-- blinddate_matches
-- blinddate_messages
-- blinddate_scheduled_matches
-- blinddate_user_actions
-- blinddate_users