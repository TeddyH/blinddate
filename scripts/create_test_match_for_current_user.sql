-- 현재 로그인한 유저에게 테스트 매칭 생성
-- 실제 유저 ID: 813e3903-e800-4fb1-a2a2-8dbd23ca5bba

DO $$
DECLARE
    current_user_id UUID := '813e3903-e800-4fb1-a2a2-8dbd23ca5bba';
    test_user_id UUID := '11111111-1111-1111-1111-111111111111';
    v_user1_id UUID;
    v_user2_id UUID;
    v_reveal_time TIMESTAMPTZ;
    v_expires_time TIMESTAMPTZ;
BEGIN
    -- 어제 날짜로 공개된 매칭 생성
    v_reveal_time := '2025-09-17 12:00:00+09'::timestamptz;
    v_expires_time := '2025-09-17 23:59:00+09'::timestamptz;

    -- user1_id < user2_id 제약 조건을 위해 정렬
    IF current_user_id < test_user_id THEN
        v_user1_id := current_user_id;
        v_user2_id := test_user_id;
    ELSE
        v_user1_id := test_user_id;
        v_user2_id := current_user_id;
    END IF;

    -- 어제 매칭 생성 (이미 공개됨)
    INSERT INTO blinddate_scheduled_matches (
        user1_id,
        user2_id,
        match_date,
        reveal_time,
        revealed_at,
        expires_at,
        status
    ) VALUES (
        v_user1_id,
        v_user2_id,
        '2025-09-17',
        v_reveal_time,
        v_reveal_time, -- 이미 공개됨
        v_expires_time,
        'revealed'
    )
    ON CONFLICT (user1_id, user2_id, match_date)
    DO UPDATE SET
        status = 'revealed',
        revealed_at = v_reveal_time;

    -- 오늘 매칭도 생성 (낮 12시에 공개 예정)
    v_reveal_time := '2025-09-18 12:00:00+09'::timestamptz;
    v_expires_time := '2025-09-18 23:59:00+09'::timestamptz;

    INSERT INTO blinddate_scheduled_matches (
        user1_id,
        user2_id,
        match_date,
        reveal_time,
        expires_at,
        status
    ) VALUES (
        v_user1_id,
        '22222222-2222-2222-2222-222222222222',
        '2025-09-18',
        v_reveal_time,
        v_expires_time,
        CASE
            WHEN NOW() >= v_reveal_time THEN 'revealed'
            ELSE 'pending'
        END
    )
    ON CONFLICT (user1_id, user2_id, match_date)
    DO UPDATE SET
        status = CASE
            WHEN NOW() >= v_reveal_time THEN 'revealed'
            ELSE 'pending'
        END,
        revealed_at = CASE
            WHEN NOW() >= v_reveal_time THEN v_reveal_time
            ELSE NULL
        END;

    RAISE NOTICE '현재 유저 매칭 생성 완료: %', current_user_id;
END $$;

-- 결과 확인
SELECT
    match_date,
    status,
    reveal_time,
    expires_at,
    CASE
        WHEN user1_id = '813e3903-e800-4fb1-a2a2-8dbd23ca5bba' THEN user2_id::text
        ELSE user1_id::text
    END as other_user_id
FROM blinddate_scheduled_matches
WHERE user1_id = '813e3903-e800-4fb1-a2a2-8dbd23ca5bba'
   OR user2_id = '813e3903-e800-4fb1-a2a2-8dbd23ca5bba'
ORDER BY match_date DESC;