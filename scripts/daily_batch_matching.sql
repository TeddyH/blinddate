-- 오늘 날짜 일일 배치 매칭 실행
-- Supabase 대시보드의 SQL Editor에서 실행하세요
--
-- 이 스크립트는 매일 자동으로 실행되어야 하는 배치 매칭 프로세스입니다.
-- 실제 운영에서는 cron job이나 Supabase Edge Function에서 실행됩니다.

DO $$
DECLARE
    v_today_date DATE := CURRENT_DATE;
    v_reveal_time TIMESTAMPTZ;
    v_expires_time TIMESTAMPTZ;
    male_users UUID[];
    female_users UUID[];
    male_count INTEGER;
    female_count INTEGER;
    match_count INTEGER := 0;
    i INTEGER;
    male_id UUID;
    female_id UUID;
    v_user1_id UUID;
    v_user2_id UUID;
    kst_time TIMESTAMPTZ;
BEGIN
    -- 한국 시간 기준으로 계산
    kst_time := NOW() AT TIME ZONE 'Asia/Seoul';

    -- 공개 시간: 오늘 낮 12시 (KST)
    v_reveal_time := (v_today_date + INTERVAL '1 day')::date + TIME '12:00:00' AT TIME ZONE 'Asia/Seoul';

    -- 만료 시간: 오늘 밤 11시 59분 (KST)
    v_expires_time := (v_today_date + INTERVAL '1 day')::date + TIME '23:59:00' AT TIME ZONE 'Asia/Seoul';

    -- 이미 낮 12시가 지났다면 내일로 설정
    IF EXTRACT(HOUR FROM kst_time) >= 12 THEN
        v_reveal_time := v_reveal_time + INTERVAL '1 day';
        v_expires_time := v_expires_time + INTERVAL '1 day';
        v_today_date := v_today_date + INTERVAL '1 day';
    END IF;

    RAISE NOTICE '배치 매칭 시작: %', v_today_date;
    RAISE NOTICE '공개 시간: %', v_reveal_time;
    RAISE NOTICE '만료 시간: %', v_expires_time;
    RAISE NOTICE '현재 KST 시간: %', kst_time;

    -- 승인된 남성 사용자 조회
    SELECT ARRAY_AGG(id ORDER BY RANDOM()) INTO male_users
    FROM blinddate_users
    WHERE approval_status = 'approved'
      AND country = 'KR'
      AND gender = 'male';

    -- 승인된 여성 사용자 조회
    SELECT ARRAY_AGG(id ORDER BY RANDOM()) INTO female_users
    FROM blinddate_users
    WHERE approval_status = 'approved'
      AND country = 'KR'
      AND gender = 'female';

    male_count := COALESCE(array_length(male_users, 1), 0);
    female_count := COALESCE(array_length(female_users, 1), 0);

    RAISE NOTICE '남성 사용자: %명, 여성 사용자: %명', male_count, female_count;

    -- 매칭 생성 (더 적은 그룹 수만큼)
    FOR i IN 1..LEAST(male_count, female_count) LOOP
        male_id := male_users[i];
        female_id := female_users[i];

        -- user1_id < user2_id 제약 조건을 위해 정렬
        IF male_id < female_id THEN
            v_user1_id := male_id;
            v_user2_id := female_id;
        ELSE
            v_user1_id := female_id;
            v_user2_id := male_id;
        END IF;

        -- 매칭 삽입
        INSERT INTO blinddate_scheduled_matches (
            user1_id,
            user2_id,
            match_date,
            reveal_time,
            expires_at,
            status
        ) VALUES (
            v_user1_id,
            v_user2_id,
            v_today_date,
            v_reveal_time,
            v_expires_time,
            'pending' -- 공개 시간까지 대기
        )
        ON CONFLICT (user1_id, user2_id, match_date) DO NOTHING;

        match_count := match_count + 1;

        RAISE NOTICE '매칭 % 생성: % <-> %', match_count, v_user1_id, v_user2_id;
    END LOOP;

    -- 배치 처리 로그 기록
    INSERT INTO blinddate_daily_match_processing (
        process_date,
        started_at,
        completed_at,
        total_eligible_users,
        total_matches_created,
        status
    ) VALUES (
        v_today_date,
        NOW(),
        NOW(),
        male_count + female_count,
        match_count,
        'completed'
    )
    ON CONFLICT (process_date) DO UPDATE SET
        completed_at = NOW(),
        total_eligible_users = male_count + female_count,
        total_matches_created = match_count,
        status = 'completed';

    RAISE NOTICE '배치 매칭 완료. 총 % 개 매칭 생성됨.', match_count;
END $$;

-- 결과 확인
SELECT
    '처리 로그' as 구분,
    process_date::text as 날짜,
    status as 상태,
    total_eligible_users as 전체사용자수,
    total_matches_created as 생성된매칭수,
    NULL::text as 사용자1,
    NULL::text as 사용자2
FROM blinddate_daily_match_processing
WHERE process_date = CURRENT_DATE

UNION ALL

SELECT
    '생성된 매칭' as 구분,
    match_date::text as 날짜,
    status as 상태,
    NULL::integer as 전체사용자수,
    NULL::integer as 생성된매칭수,
    user1_id::text as 사용자1,
    user2_id::text as 사용자2
FROM blinddate_scheduled_matches
WHERE match_date = CURRENT_DATE
ORDER BY 구분, 날짜;