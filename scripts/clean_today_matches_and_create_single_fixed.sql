-- 오늘 매칭을 모두 삭제하고 1개만 새로 생성 (user1_id < user2_id 제약 조건 준수)
-- 현재 유저(813e3903-e800-4fb1-a2a2-8dbd23ca5bba)를 위한 단일 매칭 생성

-- 1. 오늘 매칭 모두 삭제
DELETE FROM blinddate_scheduled_matches
WHERE match_date = CURRENT_DATE;

-- 2. 오늘 배치 처리 로그도 삭제
DELETE FROM blinddate_daily_match_processing
WHERE process_date = CURRENT_DATE;

-- 3. 현재 유저를 위한 1개 매칭만 생성 (user1_id < user2_id 순서 준수)
INSERT INTO blinddate_scheduled_matches (
    user1_id,
    user2_id,
    match_date,
    reveal_time,
    revealed_at,
    expires_at,
    status
) VALUES (
    '11111111-1111-1111-1111-111111111111',  -- 더 작은 ID가 user1_id
    '813e3903-e800-4fb1-a2a2-8dbd23ca5bba', -- 더 큰 ID가 user2_id
    CURRENT_DATE,
    (CURRENT_DATE + TIME '12:00:00') AT TIME ZONE 'Asia/Seoul',
    (CURRENT_DATE + TIME '12:00:00') AT TIME ZONE 'Asia/Seoul',
    (CURRENT_DATE + TIME '23:59:00') AT TIME ZONE 'Asia/Seoul',
    'revealed'
);

-- 4. 배치 처리 로그 기록
INSERT INTO blinddate_daily_match_processing (
    process_date,
    started_at,
    completed_at,
    total_eligible_users,
    total_matches_created,
    status
) VALUES (
    CURRENT_DATE,
    NOW(),
    NOW(),
    11,
    1,
    'completed'
);

-- 결과 확인
SELECT
    'Today Matches' as type,
    match_date,
    status,
    user1_id,
    user2_id,
    reveal_time,
    revealed_at
FROM blinddate_scheduled_matches
WHERE match_date = CURRENT_DATE

UNION ALL

SELECT
    'Processing Log' as type,
    process_date::text,
    status,
    NULL,
    NULL,
    NULL,
    NULL
FROM blinddate_daily_match_processing
WHERE process_date = CURRENT_DATE;