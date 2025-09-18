-- 여러 테스트 사용자 생성 및 테스트 이미지 할당

-- 기존 테스트 사용자들 삭제
DELETE FROM blinddate_users WHERE id IN (
    '11111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222',
    '33333333-3333-3333-3333-333333333333',
    '44444444-4444-4444-4444-444444444444'
);

-- 테스트 사용자 1: Snow (여성)
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
    'snow@example.com',
    'Snow',
    'KR',
    '1995-03-15',
    '안녕하세요! 새로운 인연을 찾고 있어요. 영화 보기와 여행을 좋아합니다. 😊',
    ARRAY['movies', 'travel', 'photography'],
    'approved',
    ARRAY['test/image/snow.png'],
    'female'
);

-- 테스트 사용자 2: MultiShot (남성)
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
    '22222222-2222-2222-2222-222222222222',
    'multishot@example.com',
    'MultiShot',
    'KR',
    '1992-07-20',
    '스포츠와 게임을 좋아하는 활발한 성격입니다! 함께 새로운 취미를 만들어가요.',
    ARRAY['sports', 'gaming', 'music'],
    'approved',
    ARRAY['test/image/multishot.png'],
    'male'
);

-- 테스트 사용자 3: FastBoots (여성)
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
    '33333333-3333-3333-3333-333333333333',
    'fastboots@example.com',
    'FastBoots',
    'KR',
    '1997-11-08',
    '달리기와 운동을 좋아해요! 건강한 라이프스타일을 함께 즐길 분을 찾고 있습니다.',
    ARRAY['running', 'fitness', 'cooking'],
    'approved',
    ARRAY['test/image/fastboots.png'],
    'female'
);

-- 테스트 사용자 4: FastShot (남성)
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
    '44444444-4444-4444-4444-444444444444',
    'fastshot@example.com',
    'FastShot',
    'KR',
    '1994-05-12',
    '사진 촬영과 예술을 사랑합니다. 창의적인 활동을 함께 할 수 있는 분을 만나고 싶어요!',
    ARRAY['photography', 'art', 'coffee'],
    'approved',
    ARRAY['test/image/fastshot.png'],
    'male'
);

-- 현재 매칭을 Snow와 연결하도록 업데이트
UPDATE blinddate_scheduled_matches
SET user1_id = '11111111-1111-1111-1111-111111111111',
    updated_at = NOW()
WHERE user1_id = '11111111-1111-1111-1111-111111111111'
   OR user2_id = '11111111-1111-1111-1111-111111111111';

-- 결과 확인
SELECT
    id,
    nickname,
    gender,
    LEFT(bio, 30) as bio_preview,
    profile_image_urls[1] as image_path
FROM blinddate_users
WHERE id IN (
    '11111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222',
    '33333333-3333-3333-3333-333333333333',
    '44444444-4444-4444-4444-444444444444'
)
ORDER BY nickname;