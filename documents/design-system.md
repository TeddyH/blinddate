# 디자인 시스템 (Design System)

## 디자인 철학

**"Minimal Elegance"** - 최소한의 요소로 최대한의 우아함을 표현
- 불필요한 장식 제거
- 콘텐츠에 집중할 수 있는 인터페이스
- 직관적이고 편안한 사용자 경험

## 컬러 팔레트

### Primary Colors (주요 색상)
```dart
// 메인 브랜드 컬러 - 따뜻한 중성톤
static const Color primary = Color(0xFF2D3142);      // 차콰한 네이비
static const Color primaryLight = Color(0xFF4F5D75);  // 밝은 네이비
static const Color primaryDark = Color(0xFF1A1D29);   // 진한 네이비

// 액센트 컬러 - 포인트용
static const Color accent = Color(0xFFEF476F);        // 소프트 핑크
static const Color accentLight = Color(0xFFF06B8A);   // 밝은 핑크
```

### Neutral Colors (중성 색상)
```dart
// 배경 및 텍스트용
static const Color background = Color(0xFFFCFCFC);    // 아이보리 화이트
static const Color surface = Color(0xFFF8F9FA);      // 라이트 그레이
static const Color surfaceVariant = Color(0xFFE9ECEF); // 미디엄 그레이

// 텍스트 컬러
static const Color textPrimary = Color(0xFF212529);   // 다크 그레이
static const Color textSecondary = Color(0xFF6C757D); // 미디엄 그레이
static const Color textDisabled = Color(0xFFADB5BD);  // 라이트 그레이
```

### Semantic Colors (의미 색상)
```dart
// 상태 표시용 - 매우 제한적 사용
static const Color success = Color(0xFF06D6A0);       // 소프트 그린
static const Color warning = Color(0xFFFFD166);       // 소프트 옐로우
static const Color error = Color(0xFFFF6B6B);         // 소프트 레드
static const Color info = Color(0xFF4ECDC4);          // 소프트 틸
```

## 타이포그래피

### 폰트 패밀리
```dart
// 기본: 시스템 폰트 사용으로 깔끔함 유지
static const String fontFamily = 'SF Pro Display'; // iOS
static const String fontFamilyAndroid = 'Roboto';  // Android

// 선택사항: 브랜드 정체성이 필요한 경우
// static const String brandFont = 'Pretendard'; // 한글 최적화
```

### 텍스트 스타일 정의
```dart
class AppTextStyles {
  // 헤딩
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.4,
  );

  // 바디 텍스트
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // 버튼 및 라벨
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );
}
```

## 스페이싱 시스템

### 일관된 간격 사용
```dart
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}
```

## 컴포넌트 디자인 원칙

### 1. 버튼 디자인
```dart
// Primary Button - 메인 액션용
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0, // 플랫 디자인
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
  ),
  child: Text('버튼 텍스트', style: AppTextStyles.button),
)

// Secondary Button - 보조 액션용
OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    side: BorderSide(color: AppColors.primary, width: 1.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  child: Text('보조 버튼'),
)
```

### 2. 카드 디자인
```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  ),
  padding: EdgeInsets.all(AppSpacing.lg),
  child: // 카드 내용
)
```

### 3. 입력 필드 디자인
```dart
TextFormField(
  decoration: InputDecoration(
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.md,
    ),
  ),
)
```

## 레이아웃 원칙

### 1. 화이트스페이스 활용
- 요소들 사이에 충분한 공간 확보
- 시각적 위계 구조 명확히 표현
- 콘텐츠가 숨쉴 수 있는 여백 제공

### 2. 그리드 시스템
```dart
// 기본 패딩: 좌우 16px
class AppLayout {
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets sectionPadding = EdgeInsets.all(24);
  static const double cardSpacing = 16;
}
```

### 3. 일관된 애니메이션
```dart
// 부드럽고 자연스러운 전환
static const Duration animationDuration = Duration(milliseconds: 250);
static const Curve animationCurve = Curves.easeInOut;
```

## 아이콘 시스템

### 아이콘 스타일
- **Outline 스타일**: 기본적으로 선형 아이콘 사용
- **크기**: 일관된 크기 사용 (16, 20, 24, 32px)
- **색상**: 텍스트 색상과 동일하게 맞춤

```dart
class AppIcons {
  static const double small = 16;
  static const double medium = 20;
  static const double large = 24;
  static const double xlarge = 32;
}
```

## 이미지 및 프로필 사진

### 프로필 이미지 스타일
```dart
// 원형 프로필 이미지
CircleAvatar(
  radius: 32,
  backgroundColor: AppColors.surfaceVariant,
  child: ClipOval(
    child: Image.network(
      imageUrl,
      fit: BoxFit.cover,
    ),
  ),
)

// 사각형 프로필 카드 이미지
ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: Image.network(
    imageUrl,
    fit: BoxFit.cover,
    width: double.infinity,
    height: 200,
  ),
)
```

## 다크모드 고려사항

### 색상 조정
```dart
// 다크모드 색상 팔레트
class AppColorsDark {
  static const Color background = Color(0xFF1A1D29);
  static const Color surface = Color(0xFF2D3142);
  static const Color textPrimary = Color(0xFFF8F9FA);
  static const Color textSecondary = Color(0xFFADB5BD);
}
```

## 구현 가이드라인

### 1. 컬러 사용 규칙
- **Primary**: 메인 액션 버튼, 활성 상태
- **Accent**: 하트, 좋아요, 중요한 알림
- **Neutral**: 배경, 텍스트, 구분선
- **Semantic**: 상태 메시지만 (성공/경고/오류)

### 2. 텍스트 위계
- **H1**: 화면 제목
- **H2**: 섹션 제목
- **H3**: 카드 제목
- **Body1**: 일반 내용
- **Body2**: 보조 정보
- **Caption**: 힌트, 날짜 등

### 3. 그림자 사용
```dart
// 카드용 그림자
static final BoxShadow cardShadow = BoxShadow(
  color: Colors.black.withOpacity(0.04),
  blurRadius: 8,
  offset: Offset(0, 2),
);

// 플로팅 버튼용 그림자
static final BoxShadow buttonShadow = BoxShadow(
  color: Colors.black.withOpacity(0.1),
  blurRadius: 16,
  offset: Offset(0, 4),
);
```

이 디자인 시스템을 따르면 앱 전체가 **일관되고 깔끔하며 세련된** 느낌을 유지할 수 있습니다.