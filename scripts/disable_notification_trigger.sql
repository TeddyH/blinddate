-- 중복 알림을 방지하기 위해 데이터베이스 트리거 비활성화
-- ChatService에서 알림을 처리하므로 트리거는 필요 없음

-- 기존 트리거 제거
DROP TRIGGER IF EXISTS trigger_notify_new_message ON blinddate_chat_messages;

-- 알림 함수도 제거 (필요시)
DROP FUNCTION IF EXISTS notify_new_message();

-- 참고: 트리거를 다시 활성화하려면 notification_functions.sql의 라인 43-48을 실행하세요