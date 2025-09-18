-- 공개 시간이 지난 pending 매칭들을 revealed로 업데이트
-- 현재 시간 기준으로 reveal_time이 지난 매칭들을 찾아서 상태 변경

UPDATE blinddate_scheduled_matches
SET
    status = 'revealed',
    revealed_at = reveal_time,
    updated_at = NOW()
WHERE
    status = 'pending'
    AND reveal_time <= NOW();

-- 결과 확인
SELECT
    id,
    user1_id,
    user2_id,
    match_date,
    status,
    reveal_time,
    revealed_at,
    CASE
        WHEN NOW() >= reveal_time THEN 'Should be revealed'
        ELSE 'Still pending'
    END as should_status
FROM blinddate_scheduled_matches
WHERE match_date >= CURRENT_DATE - INTERVAL '1 day'
ORDER BY match_date DESC, reveal_time DESC;