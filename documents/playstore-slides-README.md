# 플레이스토어 슬라이드 생성기 사용법

Flutter 앱으로 플레이스토어용 소개 이미지 7개를 만들 수 있습니다.

## 사용 방법

### 1. 앱 실행
```bash
flutter run lib/tools/playstore_slide_example.dart
```

### 2. 슬라이드 미리보기
- 좌우 화살표로 슬라이드 넘기기
- 7개 슬라이드 확인

### 3. 이미지 저장
- **현재 슬라이드만**: "현재 슬라이드 저장" 버튼
- **전체 7개**: 상단 다운로드 아이콘 클릭

### 4. 저장 위치
저장된 이미지는 다음 경로에서 찾을 수 있습니다:
- iOS: `/Users/[사용자명]/Library/Developer/CoreSimulator/Devices/[기기ID]/data/Containers/Data/Application/[앱ID]/Documents/`
- Android: `/data/data/com.example.blinddate/files/`

파일명: `playstore_slide_1.png` ~ `playstore_slide_7.png`

**더 쉬운 방법**: 앱에서 저장 성공 메시지에 전체 경로가 표시됩니다.

## 슬라이드 구성

1. **슬라이드 1**: 매일 한 명, 진심 어린 만남 (핵심 가치)
2. **슬라이드 2**: 철저한 프로필 검증 (안전성)
3. **슬라이드 3**: 같은 나라, 같은 관심사 (매칭)
4. **슬라이드 4**: 사용자 후기 (⭐⭐⭐⭐⭐)
5. **슬라이드 5**: 사용 방법 (3단계)
6. **슬라이드 6**: 안심하고 사용하세요 (프라이버시)
7. **슬라이드 7**: 지금 시작하세요 (CTA)

## 스크린샷 추가하는 법

각 슬라이드에 회색 박스로 스크린샷 영역이 표시되어 있습니다.

### 방법 1: Flutter 코드에서 직접 추가 (추천)
`lib/tools/playstore_slide_generator.dart` 파일을 열어서:

```dart
// 예시: 슬라이드 1의 스크린샷 영역 수정
Container(
  margin: const EdgeInsets.all(24),
  decoration: BoxDecoration(
    color: const Color(0xFF4F5D75),
    borderRadius: BorderRadius.circular(20),
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Image.asset(
      'assets/images/screenshots/matching_screen.png',
      fit: BoxFit.cover,
    ),
  ),
)
```

### 방법 2: 키노트/Photoshop에서 합성
1. 생성된 PNG 이미지를 키노트/Photoshop에서 열기
2. 회색 박스 위에 스크린샷 배치
3. 최종 이미지 내보내기

## 필요한 스크린샷 목록

1. **매칭 화면**: 오늘의 추천 사용자 프로필
2. **프로필 작성**: 프로필 정보 입력 화면
3. **관심사 선택**: 관심사 태그 선택 화면
4. **채팅 화면**: DM 대화 화면
5. **설정 화면**: 앱 설정 화면 (선택)
6. **앱 아이콘**: 런처 아이콘 또는 로그인 화면

## 커스터마이징

### 텍스트 수정
`lib/tools/playstore_slide_generator.dart`에서 각 슬라이드의 텍스트를 자유롭게 수정하세요.

### 색상 변경
디자인 시스템 색상이 적용되어 있습니다:
- Primary: `0xFF2D3142`
- Accent: `0xFFEF476F`
- Success: `0xFF06D6A0`

### 레이아웃 조정
각 `_buildSlideN()` 함수에서 레이아웃을 자유롭게 변경할 수 있습니다.

## 플레이스토어 업로드 사양

- **크기**: 1080 x 1920 px (생성된 이미지가 이미 이 크기)
- **형식**: PNG 또는 JPEG
- **최대 개수**: 8개
- **파일 크기**: 각 8MB 이하

생성된 이미지는 이미 플레이스토어 업로드 사양에 맞춰져 있습니다!

## 문제 해결

### 이미지가 저장 안 됨
- 앱 권한 확인 (파일 저장 권한)
- 디바이스 저장 공간 확인

### 텍스트가 잘림
- `playstore_slide_generator.dart`에서 폰트 크기 조정
- 텍스트 줄바꿈 추가

### 화질이 낮음
- `_captureAndSaveSlide` 함수의 `pixelRatio` 값을 높이기 (현재 3.0 → 5.0)

## 빠른 시작

```bash
# 1. 앱 실행
flutter run lib/tools/playstore_slide_example.dart

# 2. 앱에서 다운로드 아이콘 클릭 (전체 저장)

# 3. 터미널에 표시된 경로로 이동해서 이미지 확인
# 예: /Users/honghyungseok/Library/Developer/CoreSimulator/.../Documents/

# 4. 이미지를 키노트/Photoshop으로 가져와서 스크린샷 추가
```

완성! 🎉
