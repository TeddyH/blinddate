# Hearty 배치 매칭 스크립트

이 디렉토리에는 Hearty 앱의 배치 매칭 시스템 관련 SQL 스크립트들이 있습니다.

## 📋 스크립트 목록

### 1. 어제 데이터 백필 (1회성)
**파일:** `backfill_yesterday_data.sql`

**용도:**
- 어제(2025-09-17) 날짜로 매칭 데이터를 백필
- 테스트 목적으로 과거 데이터 생성
- 이미 공개된 상태로 매칭 생성

**실행 방법:**
1. [Supabase 대시보드](https://supabase.com/dashboard) 접속
2. 프로젝트 선택 (`dsjzqccyzgyjtchbbruw`)
3. **SQL Editor** 메뉴 클릭
4. `backfill_yesterday_data.sql` 파일 내용 복사/붙여넣기
5. **실행 버튼** 클릭

**결과:**
- 어제 날짜로 5개 매칭 생성
- 모든 매칭이 'revealed' 상태
- 앱에서 즉시 확인 가능

---

### 2. 일일 배치 매칭 (정기)
**파일:** `daily_batch_matching.sql`

**용도:**
- 매일 실행되는 배치 매칭 프로세스
- 실제 운영에서 사용하는 스크립트
- 낮 12시 공개 예약으로 매칭 생성

**실행 방법:**
1. [Supabase 대시보드](https://supabase.com/dashboard) 접속
2. 프로젝트 선택 (`dsjzqccyzgyjtchbbruw`)
3. **SQL Editor** 메뉴 클릭
4. `daily_batch_matching.sql` 파일 내용 복사/붙여넣기
5. **실행 버튼** 클릭

**결과:**
- 오늘 날짜로 매칭 생성
- 'pending' 상태로 생성 (낮 12시까지 대기)
- 낮 12시 이후 자동으로 'revealed' 상태로 변경

---

## 🚀 실행 순서

### 처음 설정할 때:
1. **먼저 실행:** `backfill_yesterday_data.sql` (어제 데이터 백필)
2. **앱 확인:** 어제 매칭이 표시되는지 확인
3. **다음 실행:** `daily_batch_matching.sql` (오늘 매칭 생성)

### 매일 운영할 때:
- 매일 오전에 `daily_batch_matching.sql` 실행
- 또는 cron job으로 자동화

---

## 📊 실행 결과 확인

스크립트 실행 후 결과 테이블이 표시됩니다:

| 구분 | 날짜 | 상태 | 전체사용자수 | 생성된매칭수 | 사용자1 | 사용자2 |
|------|------|------|------------|------------|---------|---------|
| 처리 로그 | 2025-09-17 | completed | 11 | 5 | NULL | NULL |
| 생성된 매칭 | 2025-09-17 | revealed | NULL | NULL | uuid1 | uuid2 |

---

## ⚠️ 주의사항

1. **중복 실행 방지:** 같은 날짜로 여러 번 실행해도 중복 생성되지 않음
2. **시간대:** 모든 시간은 한국 시간(KST) 기준
3. **데이터 백업:** 실행 전 중요 데이터 백업 권장
4. **테스트 환경:** 프로덕션 환경에서는 충분한 테스트 후 실행

---

## 🔄 자동화 방법

실제 운영에서는 다음 방법으로 자동화할 수 있습니다:

1. **Supabase Edge Function + cron trigger**
2. **GitHub Actions + 스케줄링**
3. **서버 cron job + psql**

현재는 수동 실행으로 테스트하고, 추후 자동화 시스템을 구축할 예정입니다.