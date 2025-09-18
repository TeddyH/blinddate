-- 테스트 사용자의 프로필 이미지를 실제 작동하는 URL로 업데이트

UPDATE blinddate_users
SET profile_image_urls = ARRAY['https://via.placeholder.com/400x400/4A90E2/FFFFFF?text=TestUser'],
    updated_at = NOW()
WHERE id = '11111111-1111-1111-1111-111111111111';

-- 결과 확인
SELECT
    id,
    nickname,
    gender,
    profile_image_urls
FROM blinddate_users
WHERE id = '11111111-1111-1111-1111-111111111111';