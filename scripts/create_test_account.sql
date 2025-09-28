-- Create test account for Google Play Console review
-- ID: test@tenspoon.com
-- PWD: TestUser1234!

-- Step 1: Insert user into auth.users table with verified email
INSERT INTO auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token,
    raw_app_meta_data,
    raw_user_meta_data,
    is_sso_user,
    deleted_at,
    is_anonymous
) VALUES (
    'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
    '00000000-0000-0000-0000-000000000000',
    'test@tenspoon.com',
    crypt('TestUser1234!', gen_salt('bf')), -- bcrypt hash of password
    NOW(), -- email_confirmed_at - this makes email verified
    NOW(),
    NOW(),
    '',
    '',
    '',
    '',
    '{"provider": "email", "providers": ["email"]}',
    '{}',
    false,
    NULL,
    false
);

-- Step 2: Create profile in blinddate_users table
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
    'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
    'test@tenspoon.com',
    'TestUser',
    'KR',
    '1990-01-01',
    'Google Play Console 검토용 테스트 계정입니다.',
    ARRAY['music', 'movies'],
    'approved',
    ARRAY['https://via.placeholder.com/400x400/E8E8E8/AAAAAA?text=TestUser'],
    'female'
);

-- Step 3: Create identity record for email auth
INSERT INTO auth.identities (
    provider_id,
    user_id,
    identity_data,
    provider,
    last_sign_in_at,
    created_at,
    updated_at
) VALUES (
    'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
    'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
    json_build_object(
        'sub', 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        'email', 'test@tenspoon.com',
        'email_verified', true,
        'phone_verified', false
    ),
    'email',
    NOW(),
    NOW(),
    NOW()
);

-- Verify the account was created properly
SELECT
    u.email,
    u.email_confirmed_at IS NOT NULL as email_verified,
    bu.nickname,
    bu.approval_status,
    bu.gender,
    bu.country
FROM auth.users u
JOIN blinddate_users bu ON u.id = bu.id
WHERE u.email = 'test@tenspoon.com';