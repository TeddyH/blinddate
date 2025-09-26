# Supabase Edge Function 환경변수 설정

## Firebase 서비스 계정 키 설정

Edge Function에서 Firebase FCM을 사용하기 위해 환경변수를 설정해야 합니다.

### 1. Firebase 서비스 계정 키 JSON 파일 준비

Firebase Console에서 다운로드한 서비스 계정 키 JSON 파일을 한 줄로 압축:

```bash
# JSON 파일을 한 줄로 압축 (공백과 줄바꿈 제거)
cat path/to/your/firebase-service-account.json | jq -c .
```

### 2. Supabase CLI로 환경변수 설정

```bash
# Supabase 프로젝트에 환경변수 설정
supabase secrets set FIREBASE_SERVICE_ACCOUNT_KEY='{"type":"service_account","project_id":"your-project-id",...}'
```

### 3. 환경변수 확인

```bash
# 설정된 환경변수 목록 확인
supabase secrets list
```

### 4. Edge Function 재배포

환경변수 설정 후 Edge Function을 재배포해야 합니다:

```bash
supabase functions deploy send-chat-notification
```

## 필요한 환경변수

- `FIREBASE_SERVICE_ACCOUNT_KEY`: Firebase 서비스 계정 키 JSON (한 줄로 압축된 형태)

## 보안 주의사항

- 절대로 Firebase 서비스 계정 키를 git에 커밋하지 마세요
- 환경변수로만 관리하세요
- `.gitignore`에 모든 Firebase 인증 파일들이 추가되어 있습니다