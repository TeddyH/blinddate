#!/bin/bash
# Ollama API curl 테스트 스크립트

echo "=========================================="
echo "Ollama API Curl 테스트"
echo "=========================================="

# 색상 정의
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 서버 상태 확인
echo -e "\n${YELLOW}[1] Ollama 서버 상태 확인${NC}"
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Ollama 서버 실행 중${NC}"
else
    echo -e "${RED}❌ Ollama 서버 연결 실패${NC}"
    echo "다음 명령어로 Ollama를 실행하세요:"
    echo "  $ ollama serve"
    exit 1
fi

# 2. 단일 메시지 테스트
echo -e "\n${YELLOW}[2] 단일 메시지 테스트${NC}"
echo "사용자: 안녕? 내 이름은 철수야."
curl -s http://localhost:11434/api/chat -d '{
  "model": "llama3.2:3b",
  "messages": [
    {"role": "user", "content": "안녕? 내 이름은 철수야."}
  ],
  "stream": false
}' | jq -r '.message.content' | sed 's/^/AI: /'

# 3. 컨텍스트 없는 질문 (실패 예상)
echo -e "\n${YELLOW}[3] 컨텍스트 없는 질문 (기억 못함)${NC}"
echo "사용자: 내 이름이 뭐야?"
curl -s http://localhost:11434/api/chat -d '{
  "model": "llama3.2:3b",
  "messages": [
    {"role": "user", "content": "내 이름이 뭐야?"}
  ],
  "stream": false
}' | jq -r '.message.content' | sed 's/^/AI: /'
echo -e "${RED}❌ 이전 대화를 기억하지 못함${NC}"

# 4. 히스토리 포함 대화 (성공 예상)
echo -e "\n${YELLOW}[4] 히스토리 포함 대화 (기억함)${NC}"
echo "사용자: 내 이름은 철수야."
echo "AI: (첫 응답)"
echo "사용자: 내 이름이 뭐야?"
curl -s http://localhost:11434/api/chat -d '{
  "model": "llama3.2:3b",
  "messages": [
    {"role": "user", "content": "내 이름은 철수야."},
    {"role": "assistant", "content": "안녕하세요 철수님! 반갑습니다."},
    {"role": "user", "content": "내 이름이 뭐야?"}
  ],
  "stream": false
}' | jq -r '.message.content' | sed 's/^/AI: /'
echo -e "${GREEN}✅ 이전 대화를 기억함${NC}"

# 5. 시스템 프롬프트 포함
echo -e "\n${YELLOW}[5] 시스템 프롬프트 + 대화${NC}"
echo "사용자: 오늘 첫 데이트인데 뭘 입어야 할까?"
curl -s http://localhost:11434/api/chat -d '{
  "model": "llama3.2:3b",
  "messages": [
    {"role": "system", "content": "당신은 친근한 한국 데이팅 앱의 AI 어시스턴트입니다."},
    {"role": "user", "content": "오늘 첫 데이트인데 뭘 입어야 할까?"}
  ],
  "stream": false
}' | jq -r '.message.content' | sed 's/^/AI: /'

# 6. 스트리밍 응답
echo -e "\n${YELLOW}[6] 스트리밍 응답 테스트${NC}"
echo "사용자: 데이팅 앱에서 좋은 첫 인사말은?"
echo -n "AI: "
curl -s http://localhost:11434/api/chat -d '{
  "model": "llama3.2:3b",
  "messages": [
    {"role": "user", "content": "데이팅 앱에서 좋은 첫 인사말은?"}
  ],
  "stream": true
}' | while IFS= read -r line; do
    echo "$line" | jq -r '.message.content // empty' | tr -d '\n'
done
echo ""

echo -e "\n${GREEN}=========================================="
echo "✅ 모든 curl 테스트 완료!"
echo "==========================================${NC}"
