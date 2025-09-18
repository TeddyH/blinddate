# 기술 사양서 (Technical Specification)

## 개발 환경

### Frontend
- **Framework**: Flutter (크로스플랫폼)
- **Language**: Dart
- **Target Platforms**: iOS, Android

### Backend & Database
- **Backend Service**: Supabase
- **Database**: PostgreSQL (Supabase 제공)
- **Authentication**: Supabase Auth
- **Real-time**: Supabase Realtime
- **Storage**: Supabase Storage (프로필 이미지)

## 아키텍처

### Flutter 앱 구조
```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── routes.dart
├── core/
│   ├── constants/
│   ├── utils/
│   └── services/
├── features/
│   ├── auth/
│   │   ├── models/
│   │   ├── services/
│   │   ├── screens/
│   │   └── widgets/
│   ├── profile/
│   ├── matching/
│   ├── chat/
│   └── admin/
└── shared/
    ├── widgets/
    └── models/
```

### 상태 관리
- **Provider** 또는 **Riverpod** 사용
- 인증 상태, 사용자 프로필, 매칭 데이터 관리

## Supabase 데이터베이스 스키마

### 1. Users 테이블
```sql
users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR UNIQUE NOT NULL,
  phone VARCHAR UNIQUE NOT NULL,
  nickname VARCHAR UNIQUE NOT NULL,
  country VARCHAR NOT NULL,
  birth_date DATE,
  profile_image_url TEXT,
  bio TEXT,
  interests TEXT[], -- 관심사 배열
  approval_status VARCHAR DEFAULT 'pending', -- pending, approved, rejected
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 2. User Profiles 테이블 (확장 정보)
```sql
user_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  height INTEGER,
  job VARCHAR,
  education VARCHAR,
  location VARCHAR,
  additional_photos TEXT[], -- 추가 사진 URL 배열
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 3. Matches 테이블
```sql
matches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  target_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  action VARCHAR NOT NULL, -- 'like', 'pass'
  matched_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, target_user_id)
);
```

### 4. Daily Recommendations 테이블
```sql
daily_recommendations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  recommended_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  recommendation_date DATE NOT NULL,
  viewed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, recommended_user_id, recommendation_date)
);
```

### 5. Messages 테이블
```sql
messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  message_type VARCHAR DEFAULT 'text', -- text, image, system
  read_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 6. Admin Actions 테이블
```sql
admin_actions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id UUID REFERENCES users(id),
  target_user_id UUID REFERENCES users(id),
  action VARCHAR NOT NULL, -- approve, reject
  reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## 핵심 기능 구현 방식

### 1. 인증 시스템
- Supabase Auth의 Phone Authentication 사용
- 국가별 SMS 인증 코드 발송
- 소셜 로그인 (Google, Apple) 옵션 제공

### 2. 프로필 관리
- Supabase Storage를 통한 이미지 업로드
- 이미지 압축 및 최적화 (flutter_image_compress)
- 관리자 승인 시스템 구현

### 3. 매칭 알고리즘
- 일일 추천 시스템: 나이, 거리, 관심사 기반 필터링
- PostgreSQL 함수를 통한 추천 로직 구현
- Real-time subscriptions으로 매칭 알림

### 4. 채팅 시스템
- 기본 DM: Supabase Realtime 사용
- 실시간 메시지 전송/수신
- 읽음 표시 기능

### 5. 결제 시스템
- 프리미엄 기능을 위한 In-App Purchase
- iOS: StoreKit, Android: Google Play Billing

## 필요한 Flutter 패키지

### 핵심 패키지
```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0
  provider: ^6.0.0 # 또는 riverpod
  go_router: ^12.0.0

  # UI/UX
  flutter_svg: ^2.0.0
  cached_network_image: ^3.3.0
  image_picker: ^1.0.0
  flutter_image_compress: ^2.0.0

  # 기능
  permission_handler: ^11.0.0
  geolocator: ^10.0.0
  shared_preferences: ^2.2.0

  # 결제
  in_app_purchase: ^3.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

## 개발 단계

### Phase 1: 기본 인프라 (1-2주)
- Flutter 프로젝트 초기 설정
- Supabase 프로젝트 생성 및 데이터베이스 스키마 구축
- 기본 인증 시스템 구현

### Phase 2: 핵심 기능 (3-4주)
- 사용자 프로필 생성/관리
- 관리자 승인 시스템
- 매칭 시스템 구현

### Phase 3: 소통 기능 (2-3주)
- 기본 DM 시스템
- 실시간 채팅 (프리미엄)
- 알림 시스템

### Phase 4: 최적화 및 배포 (1-2주)
- 성능 최적화
- 앱스토어 배포 준비
- 결제 시스템 연동

## 보안 고려사항

- Row Level Security (RLS) 정책 설정
- API 키 및 환경변수 관리
- 사용자 데이터 암호화
- 프로필 이미지 자동 검열 시스템 고려