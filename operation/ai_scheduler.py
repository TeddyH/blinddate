#!/usr/bin/env python3
"""
BlindDate AI User 자동 응답 스케줄러

AI 사용자가 실제 사람처럼 자연스럽게 LIKE에 응답하도록
예약된 액션들을 처리하는 백그라운드 서비스입니다.

실행 방법:
    python3 ai_scheduler.py

환경 변수:
    SUPABASE_URL: Supabase 프로젝트 URL
    SUPABASE_SERVICE_ROLE_KEY: Supabase Service Role Key
"""

import os
import sys
import time
import random
import logging
from datetime import datetime, timedelta
from typing import Dict, Any, Optional, List

import schedule
import requests
from supabase import create_client, Client
from dotenv import load_dotenv

# .env 파일 로드 (스크립트 위치 기준)
script_dir = os.path.dirname(os.path.abspath(__file__))
env_path = os.path.join(script_dir, '..', '.env')
load_dotenv(env_path)

# 로그 디렉토리 생성
log_dir = os.path.join(script_dir, 'logs')
os.makedirs(log_dir, exist_ok=True)

# 로깅 설정
log_file = os.path.join(log_dir, 'ai_scheduler.log')
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler(log_file),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# Supabase 설정
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

if not SUPABASE_URL or not SUPABASE_KEY:
    logger.error("❌ 환경 변수가 설정되지 않았습니다!")
    logger.error("   SUPABASE_URL과 SUPABASE_SERVICE_ROLE_KEY를 .env 파일에 설정하세요.")
    sys.exit(1)

try:
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    logger.info("✅ Supabase 연결 성공")
except Exception as e:
    logger.error(f"❌ Supabase 연결 실패: {e}")
    sys.exit(1)

# Ollama 설정
OLLAMA_URL = os.getenv('OLLAMA_URL', 'http://localhost:11434/api/chat')
OLLAMA_MODEL = os.getenv('OLLAMA_MODEL', 'exaone3.5:latest')

# 테이블 이름
TABLE_AI_QUEUE = 'blinddate_ai_action_queue'
TABLE_AI_SETTINGS = 'blinddate_ai_user_settings'
TABLE_AI_LOGS = 'blinddate_ai_activity_logs'
TABLE_USERS = 'blinddate_users'
TABLE_USER_ACTIONS = 'blinddate_user_actions'


class AIScheduler:
    """AI 액션 스케줄러"""

    def __init__(self):
        self.processing_count = 0
        self.success_count = 0
        self.failure_count = 0

    def run(self):
        """메인 실행 루프"""
        logger.info("="*60)
        logger.info("🤖 BlindDate AI User 자동 응답 스케줄러 시작")
        logger.info("="*60)
        logger.info(f"📍 Supabase URL: {SUPABASE_URL}")
        logger.info(f"🤖 LLM Model: {OLLAMA_MODEL}")
        logger.info(f"🌐 Ollama URL: {OLLAMA_URL}")
        logger.info(f"⏰ 체크 주기: 1분")
        logger.info("="*60)

        # 시작 시 즉시 1회 실행
        self.process_pending_actions()

        # 1분마다 실행 스케줄 등록
        schedule.every(1).minutes.do(self.process_pending_actions)

        # 1시간마다 통계 출력
        schedule.every(1).hours.do(self.print_statistics)

        logger.info("\n⏰ 스케줄러 실행 중... (Ctrl+C로 종료)\n")

        try:
            while True:
                schedule.run_pending()
                time.sleep(10)
        except KeyboardInterrupt:
            logger.info("\n\n⚠️  사용자에 의해 중단됨")
            self.print_statistics()
            sys.exit(0)

    def process_pending_actions(self):
        """예약된 AI 액션들을 처리"""
        try:
            # 실행 시간이 된 pending 액션들 조회
            response = supabase.table(TABLE_AI_QUEUE).select('*').lte(
                'scheduled_at', datetime.now().isoformat()
            ).eq('status', 'pending').order('scheduled_at').limit(10).execute()

            actions = response.data

            if not actions:
                logger.debug("📭 처리할 액션 없음")
                return

            logger.info(f"\n{'='*60}")
            logger.info(f"📬 {len(actions)}개의 예약된 액션 발견!")
            logger.info(f"{'='*60}")

            for action in actions:
                self.process_single_action(action)

        except Exception as e:
            logger.error(f"❌ 액션 조회 중 에러: {e}")

    def process_single_action(self, action: Dict[str, Any]):
        """단일 AI 액션 처리"""
        action_id = action['id']
        action_type = action['action_type']
        ai_user_id = action['ai_user_id']
        target_user_id = action['target_user_id']

        logger.info(f"\n🎯 액션 처리 시작")
        logger.info(f"   ID: {action_id[:13]}...")
        logger.info(f"   타입: {action_type}")
        logger.info(f"   AI User: {ai_user_id[:13]}...")
        logger.info(f"   Target: {target_user_id[:13]}...")

        self.processing_count += 1

        try:
            # 상태를 processing으로 변경
            supabase.table(TABLE_AI_QUEUE).update({
                'status': 'processing',
                'updated_at': datetime.now().isoformat()
            }).eq('id', action_id).execute()

            # 액션 타입별 처리
            if action_type == 'respond_to_like':
                self.handle_respond_to_like(action)
            elif action_type == 'send_chat_message':
                self.handle_send_chat_message(action)
            elif action_type == 'view_profile':
                self.handle_view_profile(action)
            else:
                raise ValueError(f"Unknown action type: {action_type}")

            # 완료 처리
            supabase.table(TABLE_AI_QUEUE).update({
                'status': 'completed',
                'executed_at': datetime.now().isoformat(),
                'updated_at': datetime.now().isoformat()
            }).eq('id', action_id).execute()

            self.success_count += 1
            logger.info(f"✅ 액션 완료: {action_type}")

        except Exception as e:
            self.failure_count += 1
            logger.error(f"❌ 액션 실패: {e}")

            # 실패 처리
            retry_count = action.get('retry_count', 0) + 1
            max_retries = 3

            # 3회 재시도 후에도 실패하면 failed 상태로
            new_status = 'failed' if retry_count >= max_retries else 'pending'

            # 재시도 시 5분 후로 스케줄
            next_schedule = (datetime.now() + timedelta(minutes=5)).isoformat() if new_status == 'pending' else None

            update_data = {
                'status': new_status,
                'retry_count': retry_count,
                'error_message': str(e)[:500],  # 에러 메시지 길이 제한
                'updated_at': datetime.now().isoformat()
            }

            if next_schedule:
                update_data['scheduled_at'] = next_schedule

            supabase.table(TABLE_AI_QUEUE).update(update_data).eq('id', action_id).execute()

            if retry_count < max_retries:
                logger.info(f"🔄 재시도 예약 ({retry_count}/{max_retries}): {next_schedule}")

    def handle_respond_to_like(self, action: Dict[str, Any]):
        """LIKE에 대한 응답 처리"""
        ai_user_id = action['ai_user_id']
        target_user_id = action['target_user_id']

        logger.info("   💕 LIKE 응답 처리 중...")

        # 1. 이미 응답했는지 확인 (중복 방지)
        existing = supabase.table(TABLE_USER_ACTIONS).select('id').eq(
            'user_id', ai_user_id
        ).eq('target_user_id', target_user_id).execute()

        if existing.data:
            logger.warning("   ⚠️  이미 응답함, 스킵")
            return

        # 2. 프로필 데이터 조회
        ai_user = supabase.table(TABLE_USERS).select('*').eq('id', ai_user_id).single().execute().data
        real_user = supabase.table(TABLE_USERS).select('*').eq('id', target_user_id).single().execute().data

        logger.info(f"   👤 AI User: {ai_user.get('nickname', 'Unknown')}")
        logger.info(f"   👤 Real User: {real_user.get('nickname', 'Unknown')}")

        # 3. LLM에게 의사결정 요청
        decision_result = self.ask_llm_for_decision(ai_user, real_user)

        decision = decision_result['decision']  # 'like' or 'pass'
        reason = decision_result['reason']

        logger.info(f"   🧠 LLM 결정: {decision.upper()}")
        logger.info(f"   📝 이유: {reason[:80]}...")

        # 4. blinddate_user_actions에 기록
        supabase.table(TABLE_USER_ACTIONS).insert({
            'user_id': ai_user_id,
            'target_user_id': target_user_id,
            'action': decision
        }).execute()

        # 5. ai_action_queue 업데이트 (LLM 응답 기록)
        supabase.table(TABLE_AI_QUEUE).update({
            'action_data': {
                'decision': decision,
                'reason': reason
            },
            'llm_model': OLLAMA_MODEL,
            'llm_response': reason
        }).eq('id', action['id']).execute()

        # 6. 활동 로그 기록
        supabase.table(TABLE_AI_LOGS).insert({
            'ai_user_id': ai_user_id,
            'target_user_id': target_user_id,
            'activity_type': decision,
            'decision_reason': reason,
            'llm_model': OLLAMA_MODEL
        }).execute()

        logger.info(f"   ✅ {decision.upper()} 액션 기록 완료")

    def ask_llm_for_decision(self, ai_user: Dict[str, Any], real_user: Dict[str, Any]) -> Dict[str, str]:
        """LLM에게 LIKE 여부 결정 요청"""

        # 나이 계산
        def calculate_age(birth_date_str):
            try:
                birth_date = datetime.strptime(birth_date_str, '%Y-%m-%d')
                today = datetime.now()
                age = today.year - birth_date.year
                if today.month < birth_date.month or (today.month == birth_date.month and today.day < birth_date.day):
                    age -= 1
                return age
            except:
                return 25  # 기본값

        ai_age = calculate_age(ai_user.get('birth_date', '1995-01-01'))
        real_age = calculate_age(real_user.get('birth_date', '1995-01-01'))

        # interests 처리 (JSONB → 리스트)
        ai_interests = ai_user.get('interests', [])
        if isinstance(ai_interests, str):
            import json
            try:
                ai_interests = json.loads(ai_interests)
            except:
                ai_interests = []

        real_interests = real_user.get('interests', [])
        if isinstance(real_interests, str):
            import json
            try:
                real_interests = json.loads(real_interests)
            except:
                real_interests = []

        # 프롬프트 작성
        prompt = f"""당신은 데이팅 앱 사용자 "{ai_user.get('nickname', 'Unknown')}"입니다.

**당신의 프로필:**
- 나이: {ai_age}세
- 성별: {ai_user.get('gender', 'unknown')}
- 자기소개: {ai_user.get('bio', '없음')}
- 관심사: {', '.join(ai_interests) if ai_interests else '없음'}

**당신에게 호감을 표시한 사람:**
- 이름: {real_user.get('nickname', 'Unknown')}
- 나이: {real_age}세
- 성별: {real_user.get('gender', 'unknown')}
- 자기소개: {real_user.get('bio', '없음')}
- 관심사: {', '.join(real_interests) if real_interests else '없음'}

**질문:**
이 사람이 당신에게 LIKE를 보냈습니다.
당신의 프로필, 관심사, 나이, 성별을 고려하여 이 사람에게 호감을 표시할지 결정하세요.

다음 형식으로 대답하세요:
결정: LIKE 또는 PASS
이유: (1-2문장으로 간단히)

자연스럽고 현실적인 판단을 해주세요.
"""

        # Ollama API 호출
        try:
            logger.info(f"   🤖 LLM 호출 중... ({OLLAMA_MODEL})")

            response = requests.post(OLLAMA_URL, json={
                'model': OLLAMA_MODEL,
                'messages': [
                    {
                        'role': 'system',
                        'content': '당신은 데이팅 앱 사용자입니다. 자연스럽고 현실적인 판단을 하세요.'
                    },
                    {'role': 'user', 'content': prompt}
                ],
                'stream': False
            }, timeout=60)

            if response.status_code != 200:
                raise Exception(f"Ollama API 오류: {response.status_code}")

            result = response.json()
            answer = result['message']['content']

            logger.info(f"   ✅ LLM 응답 받음 ({len(answer)}자)")

            # 응답 파싱
            if 'LIKE' in answer.upper() and 'PASS' not in answer.upper():
                decision = 'like'
            else:
                decision = 'pass'

            return {
                'decision': decision,
                'reason': answer
            }

        except Exception as e:
            logger.error(f"   ❌ LLM 호출 실패: {e}")

            # Fallback: AI 설정의 response_rate 기반 랜덤 결정
            try:
                settings = supabase.table(TABLE_AI_SETTINGS).select('response_rate').eq(
                    'ai_user_id', ai_user['id']
                ).single().execute().data

                response_rate = settings.get('response_rate', 0.7) if settings else 0.7
            except:
                response_rate = 0.7

            decision = 'like' if random.random() < response_rate else 'pass'

            logger.warning(f"   🎲 Fallback 랜덤 결정: {decision.upper()} (확률: {response_rate})")

            return {
                'decision': decision,
                'reason': f'LLM 오류로 인한 랜덤 결정 (response_rate={response_rate}): {str(e)}'
            }

    def handle_send_chat_message(self, action: Dict[str, Any]):
        """채팅 메시지 전송 (미래 기능)"""
        logger.info("   💬 채팅 메시지 전송 (미구현)")
        # TODO: 채팅 메시지 전송 로직
        pass

    def handle_view_profile(self, action: Dict[str, Any]):
        """프로필 조회 시뮬레이션 (미래 기능)"""
        logger.info("   👁 프로필 조회 (미구현)")
        # TODO: 프로필 조회 로그 기록
        pass

    def print_statistics(self):
        """통계 출력"""
        logger.info("\n" + "="*60)
        logger.info("📊 스케줄러 통계")
        logger.info("="*60)
        logger.info(f"   처리된 액션: {self.processing_count}개")
        logger.info(f"   성공: {self.success_count}개")
        logger.info(f"   실패: {self.failure_count}개")
        logger.info(f"   성공률: {(self.success_count / self.processing_count * 100) if self.processing_count > 0 else 0:.1f}%")
        logger.info("="*60 + "\n")


def main():
    """메인 함수"""
    scheduler = AIScheduler()
    scheduler.run()


if __name__ == "__main__":
    main()
