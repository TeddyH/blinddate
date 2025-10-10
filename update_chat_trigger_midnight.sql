-- =====================================================
-- AI 채팅 응답 트리거 업데이트: 자정 이후 응답 연기 로직 추가
-- =====================================================
-- 수정일: 2025-10-10
-- 설명: 자정(0시) ~ 활동 시작 시간 사이에 메시지를 받으면 당일 아침 활동 시작 시간에 응답하도록 수정

CREATE OR REPLACE FUNCTION blinddate_schedule_ai_chat_response()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_is_sender_ai BOOLEAN;
  v_receiver_id UUID;
  v_is_receiver_ai BOOLEAN;
  v_ai_user_id UUID;
  v_real_user_id UUID;
  v_min_chat_delay INT;
  v_max_chat_delay INT;
  v_active_start INT;
  v_active_end INT;
  v_is_active BOOLEAN;
  v_chattiness DECIMAL;
  v_random_delay INT;
  v_scheduled_time TIMESTAMPTZ;
  v_should_respond BOOLEAN;
  v_hour INT;
BEGIN
  -- 1. 송신자가 AI인지 확인
  SELECT is_ai_user INTO v_is_sender_ai
  FROM blinddate_users
  WHERE id = NEW.sender_id;

  -- AI가 보낸 메시지면 스킵 (AI는 AI에게 응답 안함)
  IF v_is_sender_ai THEN
    RETURN NEW;
  END IF;

  -- 2. 채팅방에서 상대방(수신자) 찾기
  SELECT
    CASE
      WHEN user1_id = NEW.sender_id THEN user2_id
      ELSE user1_id
    END INTO v_receiver_id
  FROM blinddate_chat_rooms
  WHERE id = NEW.chat_room_id;

  IF v_receiver_id IS NULL THEN
    RAISE NOTICE '채팅방에서 수신자를 찾을 수 없음: chat_room_id=%', NEW.chat_room_id;
    RETURN NEW;
  END IF;

  -- 3. 수신자가 AI인지 확인
  SELECT is_ai_user INTO v_is_receiver_ai
  FROM blinddate_users
  WHERE id = v_receiver_id;

  -- 수신자가 AI가 아니면 스킵
  IF NOT v_is_receiver_ai THEN
    RETURN NEW;
  END IF;

  -- AI User와 Real User 설정
  v_ai_user_id := v_receiver_id;
  v_real_user_id := NEW.sender_id;

  -- 4. AI 설정 조회
  SELECT
    COALESCE(min_chat_delay_minutes, 5),
    COALESCE(max_chat_delay_minutes, 120),
    COALESCE(active_hours_start, 9),
    COALESCE(active_hours_end, 23),
    COALESCE(is_active, TRUE),
    COALESCE(chattiness, 0.5)
  INTO v_min_chat_delay, v_max_chat_delay, v_active_start, v_active_end, v_is_active, v_chattiness
  FROM blinddate_ai_user_settings
  WHERE ai_user_id = v_ai_user_id;

  -- 설정이 없으면 기본값 사용
  IF v_min_chat_delay IS NULL THEN
    v_min_chat_delay := 5;
    v_max_chat_delay := 120;
    v_active_start := 9;
    v_active_end := 23;
    v_is_active := TRUE;
    v_chattiness := 0.5;
  END IF;

  -- 5. AI가 비활성화되어 있으면 스킵
  IF NOT v_is_active THEN
    RAISE NOTICE 'AI User가 비활성화됨, 스킵: AI=%', v_ai_user_id;
    RETURN NEW;
  END IF;

  -- 6. Chattiness 기반 응답 여부 결정 (확률적)
  v_should_respond := random() < v_chattiness;

  IF NOT v_should_respond THEN
    RAISE NOTICE 'AI가 chattiness 확률로 응답하지 않기로 결정: AI=%, chattiness=%',
      v_ai_user_id, v_chattiness;
    RETURN NEW;
  END IF;

  -- 7. 이미 스케줄된 응답이 있는지 확인 (중복 방지)
  IF EXISTS (
    SELECT 1 FROM blinddate_ai_action_queue
    WHERE ai_user_id = v_ai_user_id
      AND target_user_id = v_real_user_id
      AND action_type = 'send_chat_message'
      AND action_data->>'chat_room_id' = NEW.chat_room_id::TEXT
      AND status IN ('pending', 'processing')
  ) THEN
    RAISE NOTICE 'AI 채팅 응답이 이미 스케줄됨, 스킵: AI=%, 실제=%', v_ai_user_id, v_real_user_id;
    RETURN NEW;
  END IF;

  -- 8. 현재 시간 체크 (자정 이후는 바로 다음날로 연기)
  v_hour := EXTRACT(HOUR FROM NOW());

  -- 자정(0시) 이후는 즉시 당일 아침으로 스케줄
  IF v_hour >= 0 AND v_hour < v_active_start THEN
    -- 오늘 오전 활동 시작 시간으로 조정
    v_scheduled_time := date_trunc('day', NOW()) + (v_active_start || ' hours')::INTERVAL;
    v_random_delay := 0;  -- 지연 시간 무시
    RAISE NOTICE 'AI 자정 이후 메시지 수신 -> 오늘 %시에 응답 예정', v_active_start;
  ELSE
    -- 9. 랜덤 지연 시간 계산 (분 단위)
    v_random_delay := v_min_chat_delay + floor(random() * (v_max_chat_delay - v_min_chat_delay + 1));
    v_scheduled_time := NOW() + (v_random_delay || ' minutes')::INTERVAL;

    -- 10. 활동 시간대 체크
    v_hour := EXTRACT(HOUR FROM v_scheduled_time);

    -- 비활동 시간이면 다음 활동 시간으로 조정
    IF v_hour < v_active_start THEN
      -- 오전 활동 시작 시간으로 조정
      v_scheduled_time := date_trunc('day', v_scheduled_time) + (v_active_start || ' hours')::INTERVAL;
    ELSIF v_hour >= v_active_end THEN
      -- 다음날 오전 활동 시작 시간으로 조정
      v_scheduled_time := date_trunc('day', v_scheduled_time) + INTERVAL '1 day' + (v_active_start || ' hours')::INTERVAL;
    END IF;
  END IF;

  -- 11. 큐에 등록
  INSERT INTO blinddate_ai_action_queue (
    ai_user_id,
    target_user_id,
    action_type,
    action_data,
    scheduled_at,
    status
  ) VALUES (
    v_ai_user_id,
    v_real_user_id,
    'send_chat_message',
    jsonb_build_object(
      'chat_room_id', NEW.chat_room_id,
      'trigger_message_id', NEW.id,
      'trigger_message', NEW.message,
      'delay_minutes', v_random_delay,
      'chattiness', v_chattiness
    ),
    v_scheduled_time,
    'pending'
  );

  RAISE NOTICE 'AI 채팅 응답 스케줄 등록 성공: AI=%, 실제=%, 예정시간=%, 지연=%분, chattiness=%',
    v_ai_user_id, v_real_user_id, v_scheduled_time, v_random_delay, v_chattiness;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION blinddate_schedule_ai_chat_response() IS 'AI User가 채팅 메시지를 받았을 때 chattiness 기반으로 자동 응답 스케줄 등록 (자정 이후는 당일 아침으로 연기)';
