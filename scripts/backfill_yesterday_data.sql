-- 어제 날짜 (2025-09-17) 배치 매칭 백필
-- Supabase 대시보드의 SQL Editor에서 실행하세요
--
-- 실행 방법:
-- 1. https://supabase.com/dashboard 접속
-- 2. 프로젝트 선택 (dsjzqccyzgyjtchbbruw)
-- 3. SQL Editor 메뉴 클릭
-- 4. 이 스크립트 복사/붙여넣기
-- 5. 실행 버튼 클릭

-- 기존 어제 데이터가 있다면 삭제
DELETE FROM blinddate_scheduled_matches WHERE match_date = '2025-09-17';
DELETE FROM blinddate_daily_match_processing WHERE process_date = '2025-09-17';

-- 어제 배치 매칭 시뮬레이션
DO $$
DECLARE
    v_date DATE := '2025-09-17';
    v_reveal_time TIMESTAMPTZ := '2025-09-17 12:00:00+09'::timestamptz; -- 한국 시간 낮 12시
    v_expires_time TIMESTAMPTZ := '2025-09-17 23:59:00+09'::timestamptz; -- 한국 시간 밤 11시 59분
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
BEGIN
    RAISE NOTICE '어제 배치 매칭 시작: %', v_date;
    RAISE NOTICE '공개 시간: %', v_reveal_time;
    RAISE NOTICE '만료 시간: %', v_expires_time;

    -- 승인된 남성 사용자 조회
    SELECT ARRAY_AGG(id) INTO male_users
    FROM blinddate_users
    WHERE approval_status = 'approved'
      AND country = 'KR'
      AND gender = 'male';

    -- 승인된 여성 사용자 조회
    SELECT ARRAY_AGG(id) INTO female_users
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
            status,
            revealed_at
        ) VALUES (
            v_user1_id,
            v_user2_id,
            v_date,
            v_reveal_time,
            v_expires_time,
            'revealed', -- 이미 공개된 상태로 설정
            v_reveal_time
        )
        ON CONFLICT (user1_id, user2_id, match_date) DO UPDATE SET
            status = 'revealed',
            revealed_at = v_reveal_time;

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
        v_date,
        v_reveal_time - INTERVAL '1 minute', -- 처리 시작 시간
        v_reveal_time, -- 처리 완료 시간
        male_count + female_count,
        match_count,
        'completed'
    )
    ON CONFLICT (process_date) DO UPDATE SET
        completed_at = v_reveal_time,
        total_eligible_users = male_count + female_count,
        total_matches_created = match_count,
        status = 'completed';

    RAISE NOTICE '어제 배치 매칭 완료. 총 % 개 매칭 생성됨.', match_count;
END $$;

-- 결과 확인
SELECT
    '어제 처리 로그' as 구분,
    process_date::text as 날짜,
    status as 상태,
    total_eligible_users as 전체사용자수,
    total_matches_created as 생성된매칭수,
    NULL::text as 사용자1,
    NULL::text as 사용자2
FROM blinddate_daily_match_processing
WHERE process_date = '2025-09-17'

UNION ALL

SELECT
    '어제 매칭' as 구분,
    match_date::text as 날짜,
    status as 상태,
    NULL::integer as 전체사용자수,
    NULL::integer as 생성된매칭수,
    user1_id::text as 사용자1,
    user2_id::text as 사용자2
FROM blinddate_scheduled_matches
WHERE match_date = '2025-09-17'
ORDER BY 구분, 날짜;