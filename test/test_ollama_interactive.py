#!/usr/bin/env python3
"""
Ollama 대화형 테스트 스크립트
실제 채팅처럼 대화를 주고받을 수 있습니다.
"""

import requests
import json
import sys

OLLAMA_URL = "http://localhost:11434/api/chat"
MODEL = "llama3.2:3b"  # 기본 모델 (명령줄 인자로 변경 가능)

def print_colored(text, color_code):
    """컬러 출력"""
    print(f"\033[{color_code}m{text}\033[0m")

def chat_interactive():
    """대화형 채팅 인터페이스"""
    print("="*60)
    print_colored(f"Ollama 대화형 테스트 ({MODEL})", "1;36")
    print("="*60)
    print_colored("명령어:", "1;33")
    print("  /exit 또는 /quit : 종료")
    print("  /clear : 대화 히스토리 초기화")
    print("  /history : 현재 대화 히스토리 보기")
    print("  /system [메시지] : 시스템 프롬프트 설정")
    print("="*60 + "\n")

    # 대화 히스토리
    messages = []
    system_prompt = "당신은 친근한 한국 데이팅 앱의 AI 어시스턴트입니다. 자연스럽고 존중하는 태도로 대화하세요."

    # 초기 시스템 프롬프트
    messages.append({
        "role": "system",
        "content": system_prompt
    })

    print_colored(f"[시스템 프롬프트 설정됨]\n{system_prompt}\n", "0;35")

    while True:
        try:
            # 사용자 입력
            user_input = input("\033[1;32m당신: \033[0m")

            # 빈 입력 무시
            if not user_input.strip():
                continue

            # 명령어 처리
            if user_input.lower() in ['/exit', '/quit']:
                print_colored("\n👋 대화를 종료합니다.", "1;33")
                break

            elif user_input.lower() == '/clear':
                messages = [{
                    "role": "system",
                    "content": system_prompt
                }]
                print_colored("\n🧹 대화 히스토리가 초기화되었습니다.\n", "1;33")
                continue

            elif user_input.lower() == '/history':
                print_colored("\n📜 대화 히스토리:", "1;33")
                for i, msg in enumerate(messages, 1):
                    role = msg['role']
                    content = msg['content'][:100] + "..." if len(msg['content']) > 100 else msg['content']
                    print(f"{i}. [{role}] {content}")
                print()
                continue

            elif user_input.lower().startswith('/system '):
                new_system = user_input[8:].strip()
                if new_system:
                    system_prompt = new_system
                    messages[0] = {
                        "role": "system",
                        "content": system_prompt
                    }
                    print_colored(f"\n✅ 시스템 프롬프트 변경됨:\n{system_prompt}\n", "0;35")
                continue

            # 사용자 메시지 추가
            messages.append({
                "role": "user",
                "content": user_input
            })

            # Ollama API 호출
            payload = {
                "model": MODEL,
                "messages": messages,
                "stream": True  # 스트리밍 응답
            }

            print("\033[1;34mAI: \033[0m", end="", flush=True)

            response = requests.post(OLLAMA_URL, json=payload, stream=True)

            if response.status_code != 200:
                print_colored(f"\n❌ 에러: {response.status_code}", "1;31")
                print(response.text)
                messages.pop()  # 실패한 메시지 제거
                continue

            # 스트리밍 응답 출력
            full_response = ""
            for line in response.iter_lines():
                if line:
                    chunk = json.loads(line)
                    if 'message' in chunk:
                        content = chunk['message']['content']
                        full_response += content
                        print(content, end="", flush=True)

                    if chunk.get('done', False):
                        # 메타데이터 출력 (옵션)
                        eval_count = chunk.get('eval_count', 0)
                        total_duration = chunk.get('total_duration', 0) / 1e9

                        print()  # 줄바꿈
                        print_colored(
                            f"  [토큰: {eval_count} | 시간: {total_duration:.2f}초]",
                            "0;90"
                        )
                        break

            # AI 응답을 히스토리에 추가
            messages.append({
                "role": "assistant",
                "content": full_response
            })

            print()  # 빈 줄

        except KeyboardInterrupt:
            print_colored("\n\n⚠️  Ctrl+C 감지. /exit 로 종료하세요.\n", "1;33")
            continue

        except Exception as e:
            print_colored(f"\n❌ 에러 발생: {e}\n", "1;31")
            import traceback
            traceback.print_exc()


def check_server():
    """서버 연결 확인"""
    try:
        response = requests.get("http://localhost:11434/api/tags", timeout=2)
        if response.status_code == 200:
            models = response.json().get('models', [])
            model_names = [m['name'] for m in models]

            if not any(MODEL in name for name in model_names):
                print_colored(f"⚠️  '{MODEL}' 모델을 찾을 수 없습니다.", "1;33")
                print("\n설치된 모델:")
                for name in model_names:
                    print(f"  - {name}")
                print(f"\n다음 명령어로 모델을 다운로드하세요:")
                print(f"  $ ollama pull {MODEL}")
                return False

            return True
    except requests.exceptions.ConnectionError:
        print_colored("❌ Ollama 서버에 연결할 수 없습니다.", "1;31")
        print("\n다음 명령어로 Ollama를 실행하세요:")
        print("  $ ollama serve")
        return False
    except Exception as e:
        print_colored(f"❌ 에러: {e}", "1;31")
        return False


if __name__ == "__main__":
    # 명령줄 인자로 모델 선택 가능
    if len(sys.argv) > 1:
        MODEL = sys.argv[1]
        print_colored(f"🤖 선택된 모델: {MODEL}\n", "1;36")

    if check_server():
        chat_interactive()
    else:
        sys.exit(1)
