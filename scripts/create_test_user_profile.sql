-- 테스트 사용자 프로필 생성 (11111111-1111-1111-1111-111111111111)
-- 매칭에서 사용되는 테스트 사용자

INSERT INTO blinddate_users (
    id,
    email,
    nickname,
    country,
    birth_date,
    bio,
    interests,
    approval_status,
    profile_image_urls,
    gender
) VALUES (
    '11111111-1111-1111-1111-111111111111',
    'test@example.com',
    'TestUser',
    'KR',
    '1995-01-01',
    '안녕하세요! 새로운 인연을 찾고 있습니다. 😊',
    ARRAY['movies', 'travel'],
    'approved',
    ARRAY['https://via.placeholder.com/400x400/E8E8E8/AAAAAA?text=TestUser'],
    'female'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    nickname = EXCLUDED.nickname,
    country = EXCLUDED.country,
    birth_date = EXCLUDED.birth_date,
    bio = EXCLUDED.bio,
    interests = EXCLUDED.interests,
    approval_status = EXCLUDED.approval_status,
    profile_image_urls = EXCLUDED.profile_image_urls,
    gender = EXCLUDED.gender,
    updated_at = NOW();

-- 결과 확인
SELECT
    id,
    nickname,
    gender,
    approval_status,
    profile_image_urls,
    LEFT(bio, 50) as bio_preview
FROM blinddate_users
WHERE id = '11111111-1111-1111-1111-111111111111';