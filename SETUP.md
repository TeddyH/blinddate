# BlindDate 앱 설정 가이드

## 1. 기존 Supabase 프로젝트 사용

### 1.1 환경 변수 설정
기존 rank 프로젝트의 Supabase 정보를 사용하여 `.env` 파일 생성:

```bash
cp .env.example .env
```

`.env` 파일에 기존 rank 프로젝트의 정보 입력:
```env
SUPABASE_URL=https://your-rank-project-id.supabase.co
SUPABASE_ANON_KEY=your-rank-project-anon-key
```

**주의:** BlindDate 앱은 `blinddate_` 프리픽스가 붙은 별도 테이블을 사용하므로 기존 rank 프로젝트 데이터와 충돌하지 않습니다.

## 2. Supabase 데이터베이스 스키마 설정

### 2.1 SQL Editor에서 테이블 생성
기존 rank 프로젝트의 Supabase 대시보드에서 SQL Editor로 이동하여 다음 스크립트 실행:

```sql
-- BlindDate Users 테이블 생성 (blinddate_ 프리픽스 사용)
CREATE TABLE blinddate_users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR UNIQUE NOT NULL,
  nickname VARCHAR UNIQUE NOT NULL,
  country VARCHAR NOT NULL,
  birth_date DATE,
  profile_image_url TEXT,
  bio TEXT,
  interests TEXT[],
  approval_status VARCHAR DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- BlindDate User Profiles 테이블 생성
CREATE TABLE blinddate_user_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES blinddate_users(id) ON DELETE CASCADE,
  height INTEGER,
  job VARCHAR,
  education VARCHAR,
  location VARCHAR,
  additional_photos TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- BlindDate Matches 테이블 생성
CREATE TABLE blinddate_matches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES blinddate_users(id) ON DELETE CASCADE,
  target_user_id UUID REFERENCES blinddate_users(id) ON DELETE CASCADE,
  action VARCHAR NOT NULL CHECK (action IN ('like', 'pass')),
  matched_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, target_user_id)
);

-- BlindDate Daily Recommendations 테이블 생성
CREATE TABLE blinddate_daily_recommendations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES blinddate_users(id) ON DELETE CASCADE,
  recommended_user_id UUID REFERENCES blinddate_users(id) ON DELETE CASCADE,
  recommendation_date DATE NOT NULL,
  viewed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, recommended_user_id, recommendation_date)
);

-- BlindDate Messages 테이블 생성
CREATE TABLE blinddate_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  match_id UUID REFERENCES blinddate_matches(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES blinddate_users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  message_type VARCHAR DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'system')),
  read_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- BlindDate Admin Actions 테이블 생성
CREATE TABLE blinddate_admin_actions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id UUID REFERENCES blinddate_users(id),
  target_user_id UUID REFERENCES blinddate_users(id),
  action VARCHAR NOT NULL CHECK (action IN ('approve', 'reject')),
  reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 2.2 Row Level Security (RLS) 설정
각 테이블에 대한 보안 정책 설정:

```sql
-- BlindDate Users 테이블 RLS 활성화
ALTER TABLE blinddate_users ENABLE ROW LEVEL SECURITY;

-- 사용자는 자신의 데이터만 볼 수 있음
CREATE POLICY "BlindDate users can view own data" ON blinddate_users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "BlindDate users can update own data" ON blinddate_users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "BlindDate users can insert own data" ON blinddate_users FOR INSERT WITH CHECK (auth.uid() = id);

-- 다른 BlindDate 테이블들도 동일하게 RLS 설정
ALTER TABLE blinddate_user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE blinddate_matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE blinddate_daily_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE blinddate_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE blinddate_admin_actions ENABLE ROW LEVEL SECURITY;
```

## 3. 이메일 인증 설정

### 3.1 Authentication 설정
1. **rank 프로젝트 Supabase 대시보드**에서 **Authentication** → **Settings**로 이동
2. **Email Auth** 섹션에서 **"Enable email confirmations"** 체크박스 활성화
3. **"Confirm email"**을 **활성화** (이메일 인증 필수)

### 3.2 Site URL 및 Redirect URL 설정 (중요!)
**Authentication** → **URL Configuration**에서:

1. **Site URL** 설정:
   ```
   blinddate://login-callback/
   ```

2. **Redirect URLs** 추가:
   ```
   blinddate://login-callback/
   http://localhost:3000
   ```

**주의**: 이 설정을 하지 않으면 이메일 확인 링크가 올바르게 작동하지 않습니다.

### 3.3 이메일 템플릿 설정 (선택사항)
**Authentication** → **Email Templates**에서:
- **Confirm signup**: 회원가입 확인 이메일 템플릿
- **Magic Link**: 매직 링크 이메일 템플릿
- **Change Email Address**: 이메일 변경 확인 템플릿

### 3.4 SMTP 설정 (선택사항)
개발 단계에서는 Supabase 기본 이메일 서비스 사용 가능하지만, 프로덕션에서는 커스텀 SMTP 설정 권장:
- **Gmail SMTP**
- **SendGrid**
- **AWS SES**
- **Mailgun** 등

## 4. Storage 설정 (프로필 이미지용)

### 4.1 Storage Bucket 생성
1. Supabase 대시보드에서 Storage로 이동
2. "Create bucket" 클릭
3. Bucket 이름: `blinddate-profile-images`
4. Public bucket으로 설정

### 4.2 Storage 정책 설정
```sql
-- BlindDate 프로필 이미지 업로드 정책
CREATE POLICY "BlindDate users can upload own profile images" ON storage.objects
FOR INSERT WITH CHECK (bucket_id = 'blinddate-profile-images' AND auth.uid()::text = (storage.foldername(name))[1]);

-- BlindDate 프로필 이미지 조회 정책
CREATE POLICY "Anyone can view BlindDate profile images" ON storage.objects
FOR SELECT USING (bucket_id = 'blinddate-profile-images');
```

## 5. 앱 실행

모든 설정이 완료되면:

```bash
flutter pub get
flutter run
```

이제 휴대폰 인증이 정상적으로 작동해야 합니다!

## 문제 해결

### 일반적인 오류들:

#### 이메일 확인 관련
1. **localhost:3000 리다이렉트 오류**:
   - Supabase Authentication → URL Configuration에서 Site URL을 `blinddate://login-callback/`로 설정
   - Redirect URLs에 `blinddate://login-callback/` 추가

2. **"Email link is invalid or has expired"**:
   - 이메일 링크는 24시간 후 만료됨
   - 새로운 회원가입 시도 또는 비밀번호 재설정 이용

3. **이메일이 오지 않는 경우**:
   - 스팸 폴더 확인
   - Supabase Authentication 설정에서 "Enable email confirmations" 활성화 확인

#### 기타 오류들
4. **"No host specified in URI"**: `.env` 파일의 SUPABASE_URL 확인
5. **"Invalid API key"**: SUPABASE_ANON_KEY 확인
6. **RLS 오류**: 테이블의 Row Level Security 정책 확인

#### 개발 중 임시 해결책
이메일 확인을 건너뛰려면 Supabase에서:
1. Authentication → Settings → Email Auth
2. "Enable email confirmations" 체크박스 **해제**
3. 이렇게 하면 이메일 확인 없이 바로 로그인 가능 (개발용만)