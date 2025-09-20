-- 현재 시간이 reveal_time을 지난 pending 매칭들을 revealed로 업데이트

UPDATE blinddate_scheduled_matches
SET
  status = 'revealed',
  revealed_at = NOW(),
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
  reveal_time,
  status,
  revealed_at
FROM blinddate_scheduled_matches
WHERE match_date = CURRENT_DATE
ORDER BY created_at DESC;