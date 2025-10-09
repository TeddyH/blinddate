#!/usr/bin/env python3
"""
Ollama API 테스트 스크립트
llama3.2:3b 모델을 사용한 간단한 대화 테스트
"""

import requests
import json
import sys

# Ollama API 엔드포인트
OLLAMA_URL = "http://localhost:11434/api/chat"
MODEL = "llama3.2:3b"  # 기본 모델 (명령줄 인자로 변경 가능)

def test_single_message():
    """단일 메시지 테스트 (컨텍스트 없음)"""
    print("\n" + "="*50)
    print("테스트 1: 단일 메시지 (컨텍스트 없음)")
    print("="*50)

    payload = {
        "model": MODEL,
        "messages": [
            {
                "role": "user",
                "content": "안녕? 내 이름은 철수야."
            }
        ],
        "stream": False
    }

    response = requests.post(OLLAMA_URL, json=payload)

    if response.status_code == 200:
        result = response.json()
        print(f"사용자: {payload['messages'][0]['content']}")
        print(f"AI: {result['message']['content']}")
        print(f"\n메타데이터:")
        print(f"  - 모델: {result.get('model', 'N/A')}")
        print(f"  - 총 토큰: {result.get('eval_count', 'N/A')}")
        print(f"  - 생성 시간: {result.get('total_duration', 0) / 1e9:.2f}초")
    else:
        print(f"❌ 에러: {response.status_code}")
        print(response.text)


def test_context_without_history():
    """컨텍스트 없이 이어지는 질문 테스트 (실패 예상)"""
    print("\n" + "="*50)
    print("테스트 2: 컨텍스트 없이 이어지는 질문 (기억 못함)")
    print("="*50)

    # 첫 번째 메시지
    payload1 = {
        "model": MODEL,
        "messages": [
            {"role": "user", "content": "내 이름은 철수야."}
        ],
        "stream": False
    }

    response1 = requests.post(OLLAMA_URL, json=payload1)
    result1 = response1.json()
    print(f"사용자: 내 이름은 철수야.")
    print(f"AI: {result1['message']['content']}\n")

    # 두 번째 메시지 (히스토리 없음)
    payload2 = {
        "model": MODEL,
        "messages": [
            {"role": "user", "content": "내 이름이 뭐야?"}
        ],
        "stream": False
    }

    response2 = requests.post(OLLAMA_URL, json=payload2)
    result2 = response2.json()
    print(f"사용자: 내 이름이 뭐야?")
    print(f"AI: {result2['message']['content']}")
    print(f"❌ 예상대로 이전 대화를 기억하지 못함")


def test_context_with_history():
    """전체 히스토리를 포함한 대화 테스트 (성공 예상)"""
    print("\n" + "="*50)
    print("테스트 3: 히스토리 포함 대화 (기억함)")
    print("="*50)

    # 대화 히스토리 구축
    messages = []

    # 첫 번째 대화
    messages.append({"role": "user", "content": "내 이름은 철수야."})

    payload = {
        "model": MODEL,
        "messages": messages,
        "stream": False
    }

    response = requests.post(OLLAMA_URL, json=payload)
    result = response.json()
    assistant_msg = result['message']['content']

    print(f"사용자: 내 이름은 철수야.")
    print(f"AI: {assistant_msg}\n")

    # AI 응답을 히스토리에 추가
    messages.append({"role": "assistant", "content": assistant_msg})

    # 두 번째 대화 (히스토리 포함)
    messages.append({"role": "user", "content": "내 이름이 뭐야?"})

    payload = {
        "model": MODEL,
        "messages": messages,
        "stream": False
    }

    response = requests.post(OLLAMA_URL, json=payload)
    result = response.json()

    print(f"사용자: 내 이름이 뭐야?")
    print(f"AI: {result['message']['content']}")
    print(f"✅ 이전 대화를 기억함!")


def test_conversation_with_system_prompt():
    """시스템 프롬프트를 포함한 대화 테스트"""
    print("\n" + "="*50)
    print("테스트 4: 시스템 프롬프트 + 대화")
    print("="*50)

    messages = [
        {
            "role": "system",
            "content": "당신은 친근한 한국 데이팅 앱의 AI 어시스턴트입니다. 존중하고 따뜻한 태도로 대화하세요."
        },
        {
            "role": "user",
            "content": "오늘 첫 데이트인데 뭘 입어야 할까?"
        }
    ]

    payload = {
        "model": MODEL,
        "messages": messages,
        "stream": False
    }

    response = requests.post(OLLAMA_URL, json=payload)
    result = response.json()

    print(f"시스템: {messages[0]['content']}\n")
    print(f"사용자: {messages[1]['content']}")
    print(f"AI: {result['message']['content']}")


def test_streaming():
    """스트리밍 응답 테스트"""
    print("\n" + "="*50)
    print("테스트 5: 스트리밍 응답")
    print("="*50)

    payload = {
        "model": MODEL,
        "messages": [
            {"role": "user", "content": "데이팅 앱에서 첫 인사 메시지를 어떻게 보내면 좋을까?"}
        ],
        "stream": True
    }

    print("사용자: 데이팅 앱에서 첫 인사 메시지를 어떻게 보내면 좋을까?")
    print("AI: ", end="", flush=True)

    response = requests.post(OLLAMA_URL, json=payload, stream=True)

    full_response = ""
    for line in response.iter_lines():
        if line:
            chunk = json.loads(line)
            if 'message' in chunk:
                content = chunk['message']['content']
                full_response += content
                print(content, end="", flush=True)

            if chunk.get('done', False):
                print()  # 줄바꿈
                break


def test_multi_turn_conversation():
    """여러 턴의 대화 테스트"""
    print("\n" + "="*50)
    print("테스트 6: 멀티턴 대화 (3턴)")
    print("="*50)

    messages = [
        {
            "role": "system",
            "content": "당신은 데이팅 앱의 AI 대화 연습 파트너입니다. 자연스럽게 대화하세요."
        }
    ]

    user_messages = [
        "안녕하세요! 프로필 봤는데 영화 좋아하신다고요?",
        "저는 액션 영화를 좋아하는데, 혹시 최근에 본 영화 있으세요?",
        "오 저도 그 영화 재미있게 봤어요! 주말에 시간 되시면 같이 영화 보는 건 어때요?"
    ]

    for i, user_msg in enumerate(user_messages, 1):
        messages.append({"role": "user", "content": user_msg})

        payload = {
            "model": MODEL,
            "messages": messages,
            "stream": False
        }

        response = requests.post(OLLAMA_URL, json=payload)
        result = response.json()
        assistant_msg = result['message']['content']

        print(f"\n[턴 {i}]")
        print(f"사용자: {user_msg}")
        print(f"AI: {assistant_msg}")

        # AI 응답을 히스토리에 추가
        messages.append({"role": "assistant", "content": assistant_msg})


def check_ollama_status():
    """Ollama 서버 상태 확인"""
    print("\n" + "="*50)
    print("Ollama 서버 상태 확인")
    print("="*50)

    try:
        # 모델 리스트 확인
        response = requests.get("http://localhost:11434/api/tags")
        if response.status_code == 200:
            models = response.json()
            print("✅ Ollama 서버 실행 중")
            print("\n설치된 모델:")
            for model in models.get('models', []):
                print(f"  - {model['name']} ({model['size'] / 1e9:.2f} GB)")
                if model['name'].startswith('llama3.2:3b'):
                    print(f"    ✅ 테스트 모델 발견!")
        else:
            print(f"⚠️  Ollama 응답 이상: {response.status_code}")
    except requests.exceptions.ConnectionError:
        print("❌ Ollama 서버에 연결할 수 없습니다.")
        print("   다음 명령어로 Ollama를 실행하세요:")
        print("   $ ollama serve")
        return False

    return True


if __name__ == "__main__":
    # 명령줄 인자로 모델 선택 가능
    if len(sys.argv) > 1:
        MODEL = sys.argv[1]

    print("=" * 50)
    print("Ollama API 테스트 시작")
    print("=" * 50)
    print(f"🤖 사용 모델: {MODEL}")
    print("=" * 50)

    # 서버 상태 확인
    if not check_ollama_status():
        exit(1)

    try:
        # 각 테스트 실행
        test_single_message()
        test_context_without_history()
        test_context_with_history()
        test_conversation_with_system_prompt()
        test_streaming()
        test_multi_turn_conversation()

        print("\n" + "="*50)
        print("✅ 모든 테스트 완료!")
        print(f"🤖 사용한 모델: {MODEL}")
        print("="*50)

    except KeyboardInterrupt:
        print("\n\n⚠️  사용자에 의해 중단됨")
    except Exception as e:
        print(f"\n❌ 에러 발생: {e}")
        import traceback
        traceback.print_exc()
