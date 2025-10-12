# Flutter 다국어화 (i18n) 작업 현황

**작업 일시**: 2025-10-12
**목표**: 글로벌 출시를 위한 한글 하드코딩 → i18n 변환
**전체 작업량**: 40개 Dart 파일, 1,113줄의 한글 텍스트

---

## ✅ 완료된 작업 (약 16% 완료)

### 1. 인프라 설정 - 100% 완료 ✅

#### 수정된 파일:
- `pubspec.yaml`
  - `flutter_localizations` SDK 추가
  - `generate: true` 설정 추가

- `l10n.yaml` (신규 생성)
  ```yaml
  arb-dir: lib/l10n
  template-arb-file: app_en.arb
  output-localization-file: app_localizations.dart
  ```

- `lib/app/app.dart`
  - `AppLocalizations.delegate` 추가
  - 지원 언어: `['en', 'ko']`

#### 생성된 리소스 파일:
- `lib/l10n/app_en.arb` - 영어 번역 (338줄)
- `lib/l10n/app_ko.arb` - 한국어 번역 (279줄)
- `lib/l10n/app_localizations.dart` - 자동 생성됨

**총 300+ 문자열 정의 완료**

---

### 2. 변환 완료된 파일 (179줄 / 1,113줄)

#### 핵심 상수 파일:
1. ✅ **`lib/core/constants/profile_options.dart`** (159줄) - **14.3%**
   - 모든 메서드를 `BuildContext` 파라미터 받도록 변경
   - 성격 태그, 관심사, 직업, 지역 등 모든 프로필 옵션 다국어화
   - MBTI는 다국어화 불필요 (그대로 유지)

#### 화면 파일:
2. ✅ **`lib/features/profile/screens/profile_screen.dart`** (8줄) - **0.7%**
   - import 추가: `import '../../../l10n/app_localizations.dart';`
   - 변환된 텍스트:
     - `'프로필'` → `l10n.profileTitle`
     - `'다시 시도'` → `l10n.retry`
     - `'프로필 정보를 불러올 수 없습니다'` → `l10n.profileError`
     - `'로그아웃'` → `l10n.profileLogout`
     - `'정말로 로그아웃하시겠습니까?'` → `l10n.profileLogoutConfirm`
     - `'취소'` → `l10n.cancel`
     - `'로그아웃 중 오류가 발생했습니다'` → `l10n.errorLogout`

3. ✅ **`lib/features/chat/screens/chat_list_screen.dart`** (12줄) - **1.1%**
   - import 추가: `import '../../../l10n/app_localizations.dart';`
   - 변환된 텍스트:
     - `'채팅'` → `l10n.chatTitle`
     - `'채팅 목록을 불러오고 있어요...'` → `l10n.chatLoading`
     - `'아직 채팅할 상대가 없어요'` → `l10n.chatEmpty`
     - `'추천받은 상대와 서로 좋아요를 누르면\n채팅을 시작할 수 있어요!'` → `l10n.chatEmptyDesc`
     - `'채팅 상대'` → `l10n.chatTitle`
     - `'대화를 시작해보세요!'` → `l10n.chatFirstMessage`
     - `'매칭 성공! 대화를 시작해보세요 💕'` → `l10n.chatFirstMessageDesc`
     - `'채팅방을 생성하는 중 오류가 발생했습니다.'` → `l10n.errorChatCreate`
     - `'채팅을 시작하는 중 오류가 발생했습니다: $e'` → `l10n.errorChatLoad(e.toString())`

**완료율: 179줄 / 1,113줄 = 16.1%**

---

## 🔄 진행 중인 작업

### ProfileOptions 사용 패턴 변경 필요
기존 코드에서 `ProfileOptions`를 사용하는 모든 곳을 수정해야 함:

**변경 전:**
```dart
ProfileOptions.locations  // 에러! context 필요
ProfileOptions.genders    // 에러! context 필요
```

**변경 후:**
```dart
ProfileOptions.locations(context)
ProfileOptions.genders(context)
ProfileOptions.drinkingStyles(context)
ProfileOptions.smokingStatuses(context)
ProfileOptions.personalityTraits(context)
// ... 등등
```

**영향받는 파일:**
- `lib/features/auth/screens/profile_setup_screen.dart` (많은 수정 필요)
- `lib/features/profile/screens/profile_edit_screen.dart`
- 기타 ProfileOptions를 사용하는 모든 파일

---

## 📝 남은 작업 (934줄, 약 84%)

### 우선순위 1: 주요 화면 (184줄)

1. ⏳ **`lib/features/auth/screens/profile_setup_screen.dart`** (62줄)
   - 가장 큰 파일, ProfileOptions 사용 많음
   - 변환 필요 텍스트:
     - `'최대 3장까지만 업로드 가능합니다'`
     - `'사진 추가'`, `'카메라로 촬영'`, `'갤러리에서 선택'`
     - `'이미지를 선택하는 중 오류가 발생했습니다: $e'`
     - `'최소 1개의 관심사를 선택해주세요.'`
     - `'프로필이 성공적으로 수정되었습니다.'`
     - `'프로필이 성공적으로 생성되었습니다. 관리자 승인을 기다려주세요.'`
     - `'프로필 생성 중 오류가 발생했습니다: $e'`
     - `'프로필 수정'`, `'프로필 설정'`
     - `'로그아웃'`
     - 모든 폼 라벨 및 힌트 텍스트 (닉네임, 자기소개, 성별, 생년월일 등)
   - **특이사항**: `_selectedLocation`, `_selectedJobCategory` 초기값을 null로 변경함

2. ⏳ **`lib/features/chat/screens/chat_screen.dart`** (35줄)
   - 변환 필요 텍스트:
     - `'첫 메시지를 보내보세요! 💕'`
     - `'서로 좋아요를 누른 특별한 인연이에요.\n자연스럽게 대화를 시작해보세요!'`
     - `'오늘'`, `'어제'`, 요일 (일, 월, 화, 수, 목, 금, 토)
     - `'메시지를 입력하세요...'`
     - `'채팅 상대'`
     - `'채팅을 불러오는 중 오류가 발생했습니다: $e'`

3. ⏳ **`lib/features/dashboard/screens/dashboard_screen.dart`** (27줄)
   - 변환 필요 텍스트:
     - `'새 소식'`
     - `'오늘의 매칭'`
     - `'오늘의 추천을 기다려보세요'`
     - `'매일 낮 12시에 새로운 인연이 찾아와요'`
     - `'매칭 팁'`
     - 공지사항 텍스트들 (얼리어댑터 혜택, 환영 메시지 등)

4. ⏳ **`lib/features/matching/screens/scheduled_home_screen.dart`** (25줄)
   - 변환 필요 텍스트:
     - `'오늘의 추천'`
     - `'오늘의 특별한 인연을 확인하고 있어요...'`
     - `'매칭 정보를 불러오는 중 오류가 발생했습니다'`
     - `'다시 시도'`
     - `'오늘은 새로운 인연이 없어요'`
     - `'내일 새로운 분을 소개해드릴게요!\n매일 낮 12시에 새로운 매칭이 공개됩니다.'`
     - `'다음 매칭까지'`
     - `'🎉 오늘의 매칭이 준비되었어요!'`
     - `'낮 12시에 공개됩니다'`
     - `'💖 좋아요를 보냈습니다!'`, `'다음 기회에 만나요'`
     - `'오류가 발생했습니다: $e'`

5. ⏳ **`lib/features/auth/screens/approval_rejected_screen.dart`** (19줄)
   - 변환 필요 텍스트:
     - 승인 거부 관련 메시지들

6. ⏳ **`lib/features/auth/screens/approval_waiting_screen.dart`** (16줄)
   - 변환 필요 텍스트:
     - `'승인 대기'`
     - `'프로필 검토 중입니다'`
     - `'안전한 만남을 위해 모든 프로필을 검토하고 있습니다.\n승인이 완료되면 알림을 보내드릴게요!'`
     - `'승인 상태 확인'`, `'확인 중...'`
     - `'프로필을 찾을 수 없습니다. 프로필을 다시 설정해주세요.'`
     - `'아직 검토 중입니다. 조금만 더 기다려주세요.'`
     - `'상태 확인 중 오류가 발생했습니다: $e'`
     - `'로그아웃'`, `'로그아웃 중 오류가 발생했습니다: $e'`
     - 검증 프로세스 설명 텍스트들

### 우선순위 2: 중간 크기 화면 (약 150줄)

7. `lib/features/profile/screens/profile_edit_screen.dart` (57줄)
8. `lib/features/auth/screens/email_auth_screen.dart` (46줄)
9. `lib/features/matching/widgets/scheduled_match_card.dart` (25줄)
10. `lib/features/matching/widgets/match_success_dialog.dart` (16줄)
11. `lib/features/profile/screens/app_settings_screen.dart` (15줄)

### 우선순위 3: 작은 파일들 (약 600줄)

나머지 29개 파일:
- Services (notification, chat 등)
- Widgets (action_buttons, user_card, profile 관련 등)
- 기타 화면들

---

## 🚀 다음 단계 작업 가이드

### 1단계: 우선순위 1 파일 변환 (184줄)

각 파일마다:
1. import 추가: `import '../../l10n/app_localizations.dart';`
2. build 메서드 시작 부분에 추가: `final l10n = AppLocalizations.of(context)!;`
3. 모든 한글 문자열을 `l10n.xxx` 형태로 변환
4. ProfileOptions 사용 시 context 전달: `ProfileOptions.xxx(context)`

### 2단계: 빌드 테스트

```bash
# 패키지 재설치 및 코드 생성
flutter pub get
flutter gen-l10n

# 분석
flutter analyze

# 빌드 테스트
flutter build apk --debug  # 또는
flutter build ios --debug
```

### 3단계: 런타임 테스트

- 한국어 환경에서 앱 실행
- 영어 환경에서 앱 실행 (디바이스 언어 설정 변경)
- 모든 화면 동작 확인

### 4단계: 나머지 파일 변환

우선순위 2, 3 파일들을 순차적으로 변환

---

## 📋 ARB 파일에 이미 정의된 주요 키

### Common UI
- `appName`, `today`, `yesterday`, `retry`, `cancel`, `confirm`, `save`, `delete`, `edit`, `close`, `loading`, `error`, `success`

### Matching
- `matchingTitle`, `matchingLoading`, `matchingError`, `matchingEmpty`, `matchingEmptyDesc`, `matchingNextMatch`, `matchingReady`, `matchingReadyTime`, `matchingReadyDesc`, `matchingLiked`, `matchingPassed`

### Chat
- `chatTitle`, `chatLoading`, `chatEmpty`, `chatEmptyDesc`, `chatPlaceholder`, `chatFirstMessage`, `chatFirstMessageDesc`
- `chatWeekdaySun`, `chatWeekdayMon`, `chatWeekdayTue`, `chatWeekdayWed`, `chatWeekdayThu`, `chatWeekdayFri`, `chatWeekdaySat`

### Profile
- `profileTitle`, `profileLogout`, `profileLogoutConfirm`, `profileError`
- `profileNickname`, `profileNicknameHint`, `profileNicknameError`, `profileNicknameMinLength`
- `profileBio`, `profileBioHint`, `profileBioError`, `profileBioMinLength`
- `profileGender`, `profileGenderError`
- `profileBirthday`, `profileBirthdayError`, `profileAgeError`
- `profileLocation`, `profileLocationHint`
- `profileJobCategory`, `profileJobCategoryHint`
- `profileDrinking`, `profileDrinkingHint`
- `profileSmoking`, `profileSmokingHint`
- `profilePhotos`, `profilePhotoAdd`, `profilePhotoCamera`, `profilePhotoGallery`, `profilePhotoMaxError`
- `profileBasicInfo`
- `profilePersonalityTitle`, `profilePersonalitySubtitle`, `profilePersonalityCount`
- `profileOthersSayTitle`, `profileOthersSaySubtitle`, `profileOthersSayCount`
- `profileIdealTypeTitle`, `profileIdealTypeSubtitle`, `profileIdealTypeCount`

### Auth
- `authApprovalWaiting`, `authApprovalWaitingDesc`, `authApprovalCheckStatus`, `authApprovalChecking`

### Dashboard
- `dashboardNews`, `dashboardTodayMatch`, `dashboardMatchingTip`, `dashboardNoMatchTitle`, `dashboardNoMatchDesc`

### Errors
- `errorGeneric`, `errorProfileNotFound`, `errorChatCreate`, `errorChatLoad`, `errorLogout`, `errorImageSelect`, `errorProfileCreate`

### Success
- `successProfileUpdated`, `successProfileUpdatedReview`, `successProfileCreated`

### Profile Options (모두 context 필요)
- Personality: `personalityHumorous`, `personalitySerious`, ... (16개)
- Others Say: `othersFunny`, `othersKind`, ... (14개)
- Ideal Type: `idealHumor`, `idealSeriousness`, ... (16개)
- Date Styles: `dateActiveActivities`, `dateRelaxedWalk`, ... (12개)
- Drinking: `drinkingNone`, `drinkingSometimes`, `drinkingOften`, `drinkingSocial`
- Smoking: `smokingNonSmoker`, `smokingSmoker`
- Job: `jobUnemployed`, `jobIT`, `jobFinance`, ... (18개)
- Interests: `interestMovies`, `interestMusic`, ... (52개)
- Locations: `locationSeoul`, `locationIncheon`, ... (12개)
- Gender: `genderMale`, `genderFemale`

---

## 🔍 알려진 이슈 및 주의사항

### 1. ProfileOptions 메서드 시그니처 변경
- **모든 static 메서드가 `BuildContext context` 파라미터 필요**
- 기존 코드에서 `ProfileOptions.xxx`를 `ProfileOptions.xxx(context)`로 변경 필수
- 특히 `profile_setup_screen.dart`와 `profile_edit_screen.dart`에서 많이 사용됨

### 2. 초기값 설정
- `profile_setup_screen.dart`에서:
  - `_selectedLocation`과 `_selectedJobCategory`를 `null`로 변경했음
  - 기존: `'서울'`, `'무직'` (하드코딩)
  - 수정: `null`

### 3. 플레이스홀더 사용
일부 문자열은 동적 값을 포함:
```dart
// ARB 파일
"errorGeneric": "오류가 발생했습니다: {error}"

// Dart 코드
l10n.errorGeneric(error.toString())
```

### 4. 생성된 파일 경로
- `lib/l10n/app_localizations.dart` (자동 생성)
- import 경로: `import '../../l10n/app_localizations.dart';` 또는 `import '../../../l10n/app_localizations.dart';` (파일 위치에 따라)

### 5. scripts 디렉토리는 제외
- `scripts/` 디렉토리의 SQL/Python 파일은 다국어화 대상이 아님
- 개발/운영 전용 스크립트이므로 한글 유지

---

## 📊 통계 요약

| 항목 | 수량 |
|------|------|
| 전체 Dart 파일 | 40개 |
| 전체 한글 텍스트 줄 수 | 1,113줄 |
| 완료된 줄 수 | 179줄 |
| 완료율 | 16.1% |
| 남은 줄 수 | 934줄 |
| ARB 리소스 키 | 300+ |
| 지원 언어 | 2개 (en, ko) |

---

## ⚡ 빠른 재개 가이드

작업을 재개할 때:

1. **현재 상태 확인**
   ```bash
   cd /Volumes/Data2TB/git-project/blinddate
   git status
   flutter analyze
   ```

2. **다음 작업할 파일 선택**
   - 우선순위 1 목록에서 선택
   - `approval_waiting_screen.dart`부터 시작 권장

3. **작업 패턴**
   ```dart
   // 1. import 추가
   import '../../l10n/app_localizations.dart';

   // 2. build 메서드에서 l10n 가져오기
   @override
   Widget build(BuildContext context) {
     final l10n = AppLocalizations.of(context)!;
     // ...
   }

   // 3. 한글 문자열 변환
   Text('한글 텍스트')  →  Text(l10n.xxxKey)

   // 4. ProfileOptions 사용 시
   ProfileOptions.locations  →  ProfileOptions.locations(context)
   ```

4. **테스트**
   ```bash
   flutter pub get
   flutter analyze
   flutter run
   ```

---

**작업 시작 지점**: `lib/features/auth/screens/approval_waiting_screen.dart`
**예상 소요 시간**: 우선순위 1 완료까지 약 3-4시간
