-- 사용자 프로필의 bio에서 "하루 2명 추천"을 "하루 1명 추천"으로 수정

UPDATE blinddate_users
SET bio = REPLACE(bio, '하루 2명 추천', '하루 1명 추천'),
    updated_at = NOW()
WHERE bio LIKE '%하루 2명 추천%';

-- 결과 확인
SELECT
    id,
    nickname,
    LEFT(bio, 100) as bio_preview
FROM blinddate_users
WHERE bio LIKE '%하루 1명 추천%';