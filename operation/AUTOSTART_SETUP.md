# AI Scheduler 자동 실행 설정 가이드

Mac 부팅 시 AI Scheduler가 자동으로 실행되도록 설정하는 방법입니다.

## 📋 사전 준비

### 1. Ollama 자동 실행 설정

AI Scheduler는 Ollama에 의존하므로 Ollama도 자동 실행되어야 합니다.

```bash
# Homebrew로 설치한 경우, Ollama가 자동으로 launchd에 등록됩니다
brew services start ollama

# 확인
brew services list | grep ollama
```

### 2. Python 의존성 설치

```bash
cd /Volumes/Data2TB/git-project/blinddate/scripts
pip3 install -r requirements.txt
```

---

## 🚀 AI Scheduler 자동 실행 설정

### 1단계: plist 파일 복사

```bash
# plist 파일을 ~/Library/LaunchAgents/로 복사
cp /Volumes/Data2TB/git-project/blinddate/operation/com.blinddate.ai-scheduler.plist \
   ~/Library/LaunchAgents/

# 권한 설정
chmod 644 ~/Library/LaunchAgents/com.blinddate.ai-scheduler.plist
```

### 2단계: 서비스 등록 및 시작

```bash
# launchd에 등록
launchctl load ~/Library/LaunchAgents/com.blinddate.ai-scheduler.plist

# 서비스 시작
launchctl start com.blinddate.ai-scheduler
```

### 3단계: 실행 확인

```bash
# 프로세스 확인
ps aux | grep ai_scheduler

# 로그 확인
tail -f /Volumes/Data2TB/git-project/blinddate/operation/logs/ai_scheduler.log

# stdout/stderr 로그 확인
tail -f /Volumes/Data2TB/git-project/blinddate/operation/logs/stdout.log
tail -f /Volumes/Data2TB/git-project/blinddate/operation/logs/stderr.log
```

---

## 🔧 관리 명령어

### 서비스 중지

```bash
launchctl stop com.blinddate.ai-scheduler
```

### 서비스 재시작

```bash
launchctl stop com.blinddate.ai-scheduler
launchctl start com.blinddate.ai-scheduler
```

### 서비스 등록 해제 (자동 실행 비활성화)

```bash
launchctl unload ~/Library/LaunchAgents/com.blinddate.ai-scheduler.plist
```

### 서비스 상태 확인

```bash
# 실행 중인지 확인
launchctl list | grep com.blinddate.ai-scheduler

# 상세 정보 확인
launchctl print gui/$(id -u)/com.blinddate.ai-scheduler
```

---

## 📊 로그 파일 위치

모든 로그는 `operation/logs/` 디렉토리에 저장됩니다:

| 파일 | 설명 |
|------|------|
| `ai_scheduler.log` | 메인 애플리케이션 로그 (스케줄러 동작, LLM 호출 등) |
| `stdout.log` | 표준 출력 로그 (launchd가 캡처) |
| `stderr.log` | 표준 에러 로그 (launchd가 캡처) |

### 로그 확인 명령어

```bash
# 메인 로그 실시간 확인
tail -f /Volumes/Data2TB/git-project/blinddate/operation/logs/ai_scheduler.log

# 에러만 필터링
grep "ERROR" /Volumes/Data2TB/git-project/blinddate/operation/logs/ai_scheduler.log

# 최근 100줄 확인
tail -100 /Volumes/Data2TB/git-project/blinddate/operation/logs/ai_scheduler.log

# LLM 결정 확인
grep "🧠 LLM 결정" /Volumes/Data2TB/git-project/blinddate/operation/logs/ai_scheduler.log
```

---

## 🔍 문제 해결

### 1. 서비스가 시작되지 않음

```bash
# plist 파일 문법 확인
plutil -lint ~/Library/LaunchAgents/com.blinddate.ai-scheduler.plist

# 권한 확인
ls -l ~/Library/LaunchAgents/com.blinddate.ai-scheduler.plist

# stderr 로그 확인
cat /Volumes/Data2TB/git-project/blinddate/operation/logs/stderr.log
```

### 2. Python 모듈을 찾을 수 없음

launchd 환경에서는 PATH가 다를 수 있습니다.

**해결 방법:**
```bash
# 시스템 Python에 의존성 설치
/usr/bin/python3 -m pip install -r /Volumes/Data2TB/git-project/blinddate/scripts/requirements.txt

# 또는 plist 파일에서 Python 경로를 명시적으로 지정 (이미 되어있음)
```

### 3. .env 파일을 찾을 수 없음

스크립트가 자동으로 `../. env`를 찾도록 수정되어 있습니다.

**.env 위치 확인:**
```bash
ls -la /Volumes/Data2TB/git-project/blinddate/.env
```

없으면:
```bash
cp /Volumes/Data2TB/git-project/blinddate/.env.example \
   /Volumes/Data2TB/git-project/blinddate/.env
# 그리고 실제 값으로 수정
```

### 4. Ollama 연결 실패

```bash
# Ollama 서비스 확인
brew services list | grep ollama

# Ollama 재시작
brew services restart ollama

# 수동 테스트
curl http://localhost:11434/api/tags
```

### 5. 서비스가 계속 재시작됨

```bash
# 로그에서 에러 확인
tail -50 /Volumes/Data2TB/git-project/blinddate/operation/logs/stderr.log

# KeepAlive를 false로 변경 (디버깅용)
# plist 파일에서 <key>KeepAlive</key> <true/> → <false/>
```

---

## 📝 plist 파일 수정

경로나 설정을 변경하려면:

```bash
# 1. 서비스 중지
launchctl unload ~/Library/LaunchAgents/com.blinddate.ai-scheduler.plist

# 2. plist 파일 수정
nano ~/Library/LaunchAgents/com.blinddate.ai-scheduler.plist

# 3. 다시 로드
launchctl load ~/Library/LaunchAgents/com.blinddate.ai-scheduler.plist
launchctl start com.blinddate.ai-scheduler
```

---

## ⚙️ plist 파일 설명

```xml
<key>RunAtLoad</key>
<true/>
<!-- Mac 부팅 시 자동 실행 -->

<key>KeepAlive</key>
<true/>
<!-- 프로세스가 종료되면 자동으로 재시작 -->

<key>StandardOutPath</key>
<string>/Volumes/Data2TB/git-project/blinddate/operation/logs/stdout.log</string>
<!-- 표준 출력을 파일로 저장 -->

<key>StandardErrorPath</key>
<string>/Volumes/Data2TB/git-project/blinddate/operation/logs/stderr.log</string>
<!-- 표준 에러를 파일로 저장 -->
```

---

## 🧪 수동 테스트 (자동 실행 전)

자동 실행 설정 전에 수동으로 테스트해보세요:

```bash
cd /Volumes/Data2TB/git-project/blinddate/operation
python3 ai_scheduler.py
```

정상 작동하면 Ctrl+C로 종료하고 launchd에 등록하세요.

---

## ✅ 완료 체크리스트

- [ ] Ollama가 자동 실행되도록 설정됨
- [ ] Python 의존성 설치 완료
- [ ] .env 파일 존재 및 값 설정 완료
- [ ] plist 파일이 `~/Library/LaunchAgents/`에 복사됨
- [ ] `launchctl load` 실행 완료
- [ ] `launchctl start` 실행 완료
- [ ] 프로세스가 실행 중인지 확인 (`ps aux | grep ai_scheduler`)
- [ ] 로그 파일에 정상 로그가 기록되는지 확인

---

**설정 완료!** 이제 Mac을 재부팅해도 AI Scheduler가 자동으로 실행됩니다. 🎉
