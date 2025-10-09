# Ollama API 테스트

이 디렉토리는 Ollama LLM API를 테스트하기 위한 스크립트들을 포함합니다.

## 사전 준비

### 1. Ollama 설치 및 실행

```bash
# Ollama 설치 (이미 설치되어 있다면 생략)
brew install ollama

# Ollama 서버 실행
ollama serve

# 새 터미널에서 모델 다운로드
ollama pull llama3.2:3b
```

### 2. Python 의존성 설치 (Python 테스트용)

```bash
pip3 install requests
```

## 테스트 스크립트

### 1. `test_ollama.py` - 종합 테스트

6가지 시나리오를 자동으로 테스트합니다:

```bash
# 기본 모델 (llama3.2:3b) 사용
python3 test_ollama.py

# 다른 모델 지정
python3 test_ollama.py exaone3.5:latest
python3 test_ollama.py llama3.2:3b
```

**테스트 항목:**
- ✅ 단일 메시지 테스트
- ❌ 컨텍스트 없는 대화 (실패 예상)
- ✅ 히스토리 포함 대화 (성공 예상)
- ✅ 시스템 프롬프트 적용
- ✅ 스트리밍 응답
- ✅ 멀티턴 대화 (3턴)

### 2. `test_ollama_curl.sh` - Curl 테스트

curl 명령어를 사용한 간단한 API 테스트:

```bash
./test_ollama_curl.sh
```

**요구사항:**
- `jq` 설치 필요: `brew install jq`

### 3. `test_ollama_interactive.py` - 대화형 테스트

실제 채팅처럼 대화를 주고받을 수 있는 인터랙티브 인터페이스:

```bash
# 기본 모델 사용
python3 test_ollama_interactive.py

# 다른 모델 지정
python3 test_ollama_interactive.py exaone3.5:latest
```

**사용 가능한 명령어:**
- `/exit` 또는 `/quit` - 종료
- `/clear` - 대화 히스토리 초기화
- `/history` - 현재 대화 히스토리 보기
- `/system [메시지]` - 시스템 프롬프트 변경

**예시:**
```
당신: 안녕? 내 이름은 철수야.
AI: 안녕하세요 철수님! 반갑습니다.

당신: 내 이름이 뭐야?
AI: 철수님이시죠!

당신: /clear
🧹 대화 히스토리가 초기화되었습니다.

당신: /system 당신은 귀여운 고양이 캐릭터입니다. 냐옹~하고 말하세요.
✅ 시스템 프롬프트 변경됨

당신: 안녕?
AI: 냐옹~ 안녕하세요! 🐱
```

## 주요 학습 포인트

### 1. 컨텍스트 유지 방법

Ollama API는 stateless이므로, 이전 대화를 기억하려면 **전체 히스토리를 매번 전송**해야 합니다:

```python
messages = [
    {"role": "system", "content": "시스템 프롬프트"},
    {"role": "user", "content": "첫 번째 질문"},
    {"role": "assistant", "content": "첫 번째 답변"},
    {"role": "user", "content": "두 번째 질문"},  # ← 새로운 질문
]
```

### 2. 시스템 프롬프트 활용

`system` role을 사용하여 AI의 성격/역할을 설정할 수 있습니다:

```python
{
    "role": "system",
    "content": "당신은 친근한 데이팅 앱 AI 어시스턴트입니다."
}
```

### 3. 스트리밍 vs 일반 응답

- **스트리밍** (`stream: true`): 실시간으로 응답을 받아 표시 (챗봇 느낌)
- **일반** (`stream: false`): 전체 응답을 한 번에 받음 (간단한 처리)

## 다음 단계

이 테스트를 통해 확인한 사항을 바탕으로:

1. **Supabase Edge Function** 작성
2. **세션 관리 서버** 구축 (Python/Node.js)
3. **Flutter 앱**과 통합

자세한 아키텍처는 상위 디렉토리의 문서를 참고하세요.
