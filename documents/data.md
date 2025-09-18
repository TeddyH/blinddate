# BlindDate Database Management

## 📊 Database Schema

### Main Tables

#### `blinddate_users` (사용자 정보)
```sql
CREATE TABLE blinddate_users (
  id UUID PRIMARY KEY,
  email VARCHAR UNIQUE NOT NULL,
  nickname VARCHAR(20) NOT NULL,
  country VARCHAR(10) NOT NULL DEFAULT 'KR',
  birth_date DATE NOT NULL,
  bio TEXT,
  interests JSONB DEFAULT '[]',
  gender VARCHAR(10) CHECK (gender IN ('male', 'female')),
  profile_image_urls JSONB DEFAULT '[]',
  approval_status VARCHAR(20) DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
  rejection_reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### `blinddate_daily_recommendations` (일일 추천)
```sql
CREATE TABLE blinddate_daily_recommendations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES blinddate_users(id) ON DELETE CASCADE,
  recommended_user_id UUID REFERENCES blinddate_users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  viewed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, recommended_user_id, date)
);
```

#### `blinddate_user_actions` (사용자 액션)
```sql
CREATE TABLE blinddate_user_actions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES blinddate_users(id) ON DELETE CASCADE,
  target_user_id UUID REFERENCES blinddate_users(id) ON DELETE CASCADE,
  action VARCHAR(10) CHECK (action IN ('like', 'pass')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### `blinddate_matches` (매칭)
```sql
CREATE TABLE blinddate_matches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user1_id UUID REFERENCES blinddate_users(id) ON DELETE CASCADE,
  user2_id UUID REFERENCES blinddate_users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user1_id, user2_id)
);
```

#### `blinddate_messages` (메시지)
```sql
CREATE TABLE blinddate_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  match_id UUID REFERENCES blinddate_matches(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES blinddate_users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### `blinddate_admin_actions` (관리자 액션)
```sql
CREATE TABLE blinddate_admin_actions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id UUID NOT NULL,
  target_user_id UUID REFERENCES blinddate_users(id) ON DELETE CASCADE,
  action VARCHAR(20) NOT NULL,
  reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## 🔐 Row Level Security (RLS) Policies

### Users Table Policies
```sql
-- 승인된 사용자 프로필 조회 허용
CREATE POLICY "BlindDate users can view profiles" ON blinddate_users
    FOR SELECT USING (
        auth.uid() = id OR approval_status = 'approved'
    );

-- 자신의 데이터 수정 허용
CREATE POLICY "BlindDate users can update own data" ON blinddate_users
    FOR UPDATE USING (auth.uid() = id);

-- 자신의 데이터 입력 허용
CREATE POLICY "BlindDate users can insert own data" ON blinddate_users
    FOR INSERT WITH CHECK (auth.uid() = id);
```

## 🗑 Data Management Commands

### Clear Recommendation Data (테스트용)
```sql
-- 모든 추천 데이터 삭제
DELETE FROM blinddate_daily_recommendations;

-- 특정 사용자의 추천 데이터 삭제
DELETE FROM blinddate_daily_recommendations WHERE user_id = 'USER_ID';

-- 특정 날짜의 추천 데이터 삭제
DELETE FROM blinddate_daily_recommendations WHERE date = '2025-09-18';
```

### Clear User Actions (테스트용)
```sql
-- 모든 사용자 액션 삭제
DELETE FROM blinddate_user_actions;

-- 특정 사용자의 액션 삭제
DELETE FROM blinddate_user_actions WHERE user_id = 'USER_ID';
```

### Clear Matches (테스트용)
```sql
-- 모든 매칭 삭제
DELETE FROM blinddate_matches;

-- 특정 사용자의 매칭 삭제
DELETE FROM blinddate_matches WHERE user1_id = 'USER_ID' OR user2_id = 'USER_ID';
```

## 📋 Test Data Management

### Create Test Users
```sql
INSERT INTO blinddate_users (id, nickname, approval_status, country, birth_date, bio, interests, gender) VALUES
('11111111-1111-1111-1111-111111111111', '서연', 'approved', 'KR', '1995-03-15', '안녕하세요! 새로운 인연을 찾고 있어요.', '["영화", "음식", "여행"]', 'female'),
('22222222-2222-2222-2222-222222222222', '민준', 'approved', 'KR', '1993-07-22', '운동과 음악을 좋아하는 사람입니다.', '["운동", "음악", "독서"]', 'male'),
('33333333-3333-3333-3333-333333333333', '지현', 'approved', 'KR', '1997-12-08', '카페투어와 사진찍기를 즐겨요.', '["사진", "카페", "예술"]', 'female'),
('44444444-4444-4444-4444-444444444444', '태현', 'approved', 'KR', '1991-05-30', '요리하는 것을 좋아합니다.', '["요리", "와인", "영화"]', 'male'),
('55555555-5555-5555-5555-555555555555', '수진', 'approved', 'KR', '1996-09-14', '반려동물과 함께하는 삶을 사랑해요.', '["반려동물", "산책", "책"]', 'female'),
('66666666-6666-6666-6666-666666666666', '현우', 'approved', 'KR', '1994-11-03', '새로운 도전을 즐기는 성격이에요.', '["여행", "스포츠", "게임"]', 'male'),
('77777777-7777-7777-7777-777777777777', '은영', 'approved', 'KR', '1998-02-18', '조용한 곳에서 책 읽는 시간이 좋아요.', '["독서", "차", "음악"]', 'female'),
('88888888-8888-8888-8888-888888888888', '준호', 'approved', 'KR', '1992-08-25', '활발하고 긍정적인 에너지를 가지고 있어요.', '["클럽", "파티", "친구"]', 'male'),
('99999999-9999-9999-9999-999999999999', '혜진', 'approved', 'KR', '1999-06-12', '예술과 문화를 사랑하는 사람이에요.', '["미술", "전시", "콘서트"]', 'female'),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '상훈', 'approved', 'KR', '1990-04-07', '진솔한 대화를 나누고 싶어요.', '["대화", "철학", "자연"]', 'male');
```

### Update Existing Users Gender
```sql
-- 기존 사용자들에게 성별 정보 추가
UPDATE blinddate_users SET gender = 'male' WHERE nickname IN ('Tim', '민준', '태현', '현우', '준호', '상훈');
UPDATE blinddate_users SET gender = 'female' WHERE nickname IN ('서연', '지현', '수진', '은영', '혜진');
```

### Reset User for Testing
```sql
-- 특정 사용자의 모든 관련 데이터 삭제 (테스트용)
DELETE FROM blinddate_daily_recommendations WHERE user_id = 'USER_ID' OR recommended_user_id = 'USER_ID';
DELETE FROM blinddate_user_actions WHERE user_id = 'USER_ID' OR target_user_id = 'USER_ID';
DELETE FROM blinddate_matches WHERE user1_id = 'USER_ID' OR user2_id = 'USER_ID';
DELETE FROM blinddate_messages WHERE sender_id = 'USER_ID';
```

## 🔍 Useful Queries

### Check User Status
```sql
-- 사용자 기본 정보 확인
SELECT id, nickname, approval_status, gender, country FROM blinddate_users WHERE email = 'user@example.com';

-- 승인된 사용자 수 확인
SELECT COUNT(*) FROM blinddate_users WHERE approval_status = 'approved';

-- 성별별 사용자 수 확인
SELECT gender, COUNT(*) FROM blinddate_users WHERE approval_status = 'approved' GROUP BY gender;
```

### Check Recommendations
```sql
-- 특정 사용자의 오늘 추천 확인
SELECT * FROM blinddate_daily_recommendations
WHERE user_id = 'USER_ID' AND date = CURRENT_DATE;

-- 특정 사용자가 받은 모든 추천 확인
SELECT dr.*, u.nickname
FROM blinddate_daily_recommendations dr
JOIN blinddate_users u ON dr.recommended_user_id = u.id
WHERE dr.user_id = 'USER_ID'
ORDER BY dr.created_at DESC;
```

### Check Actions and Matches
```sql
-- 특정 사용자의 액션 확인
SELECT ua.*, u.nickname
FROM blinddate_user_actions ua
JOIN blinddate_users u ON ua.target_user_id = u.id
WHERE ua.user_id = 'USER_ID'
ORDER BY ua.created_at DESC;

-- 특정 사용자의 매칭 확인
SELECT m.*, u1.nickname as user1_name, u2.nickname as user2_name
FROM blinddate_matches m
JOIN blinddate_users u1 ON m.user1_id = u1.id
JOIN blinddate_users u2 ON m.user2_id = u2.id
WHERE m.user1_id = 'USER_ID' OR m.user2_id = 'USER_ID';
```

## 🛠 Maintenance Commands

### Update Schema
```sql
-- 새 컬럼 추가 (예: gender 컬럼)
ALTER TABLE blinddate_users ADD COLUMN gender VARCHAR(10) CHECK (gender IN ('male', 'female'));

-- 인덱스 추가
CREATE INDEX idx_users_approval_gender ON blinddate_users(approval_status, gender);
CREATE INDEX idx_recommendations_user_date ON blinddate_daily_recommendations(user_id, date);
CREATE INDEX idx_actions_user_target ON blinddate_user_actions(user_id, target_user_id);
```

### Storage Bucket Management
```sql
-- 스토리지 버킷 생성
INSERT INTO storage.buckets (id, name, public) VALUES ('blinddate-profile-images', 'blinddate-profile-images', true);

-- 스토리지 RLS 정책
CREATE POLICY "Public Access" ON storage.objects FOR SELECT USING (bucket_id = 'blinddate-profile-images');
CREATE POLICY "Users can upload own images" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'blinddate-profile-images' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users can delete own images" ON storage.objects FOR DELETE USING (bucket_id = 'blinddate-profile-images' AND auth.uid()::text = (storage.foldername(name))[1]);
```

## ⚙ Configuration

### App Constants
- **Daily Recommendation Limit**: 1명 (변경 위치: `lib/core/constants/app_constants.dart`)
- **Max Profile Photos**: 5장
- **Max Bio Length**: 500자
- **Approval Status**: pending, approved, rejected
- **Actions**: like, pass
- **Supported Countries**: KR (한국)
- **Supported Genders**: male, female

### Table Names Mapping
```dart
// lib/core/constants/table_names.dart
static const String users = 'blinddate_users';
static const String dailyRecommendations = 'blinddate_daily_recommendations';
static const String userActions = 'blinddate_user_actions';
static const String matches = 'blinddate_matches';
static const String messages = 'blinddate_messages';
static const String adminActions = 'blinddate_admin_actions';
```