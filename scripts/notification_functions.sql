-- 알림 관련 SQL Functions 및 Triggers

-- 1. 읽지 않은 메시지 수 계산 함수
CREATE OR REPLACE FUNCTION get_unread_message_count(user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    unread_count INTEGER;
BEGIN
    SELECT COUNT(*)::INTEGER INTO unread_count
    FROM blinddate_chat_messages cm
    JOIN blinddate_chat_rooms cr ON cm.chat_room_id = cr.id
    WHERE (cr.user1_id = user_id OR cr.user2_id = user_id)
    AND cm.sender_id != user_id
    AND cm.read_at IS NULL;

    RETURN COALESCE(unread_count, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. 메시지 전송 시 자동으로 알림 발송하는 트리거
CREATE OR REPLACE FUNCTION notify_new_message()
RETURNS TRIGGER AS $$
BEGIN
    -- Supabase Edge Function 호출 (pg_net extension 필요)
    SELECT
        net.http_post(
            url := 'https://your-project.supabase.co/functions/v1/send-chat-notification',
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || 'your-service-role-key'
            ),
            body := jsonb_build_object(
                'chatRoomId', NEW.chat_room_id,
                'senderId', NEW.sender_id,
                'message', NEW.message
            )
        ) as request_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. 트리거 생성
DROP TRIGGER IF EXISTS trigger_notify_new_message ON blinddate_chat_messages;
CREATE TRIGGER trigger_notify_new_message
    AFTER INSERT ON blinddate_chat_messages
    FOR EACH ROW
    EXECUTE FUNCTION notify_new_message();

-- 4. 사용자 테이블에 FCM 토큰 컬럼 추가 (이미 있다면 스킵)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'blinddate_users'
        AND column_name = 'fcm_token'
    ) THEN
        ALTER TABLE blinddate_users ADD COLUMN fcm_token TEXT;
        CREATE INDEX IF NOT EXISTS idx_users_fcm_token ON blinddate_users(fcm_token);
    END IF;
END $$;

-- 5. 읽지 않은 메시지가 있는 채팅방 조회 함수
CREATE OR REPLACE FUNCTION get_chat_rooms_with_unread(user_id UUID)
RETURNS TABLE (
    chat_room_id UUID,
    other_user_id UUID,
    other_user_name TEXT,
    last_message TEXT,
    last_message_at TIMESTAMP WITH TIME ZONE,
    unread_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        cr.id as chat_room_id,
        CASE
            WHEN cr.user1_id = user_id THEN cr.user2_id
            ELSE cr.user1_id
        END as other_user_id,
        CASE
            WHEN cr.user1_id = user_id THEN u2.nickname
            ELSE u1.nickname
        END as other_user_name,
        cr.last_message,
        cr.last_message_at,
        COALESCE(unread.count, 0)::INTEGER as unread_count
    FROM blinddate_chat_rooms cr
    LEFT JOIN blinddate_users u1 ON cr.user1_id = u1.id
    LEFT JOIN blinddate_users u2 ON cr.user2_id = u2.id
    LEFT JOIN (
        SELECT
            chat_room_id,
            COUNT(*) as count
        FROM blinddate_chat_messages
        WHERE sender_id != user_id
        AND read_at IS NULL
        GROUP BY chat_room_id
    ) unread ON cr.id = unread.chat_room_id
    WHERE cr.user1_id = user_id OR cr.user2_id = user_id
    ORDER BY cr.updated_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. RLS 정책 (FCM 토큰 접근용)
CREATE POLICY "Users can update their own FCM token"
ON blinddate_users FOR UPDATE
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- 7. 알림 설정 테이블 (선택사항)
CREATE TABLE IF NOT EXISTS blinddate_notification_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES blinddate_users(id) ON DELETE CASCADE,
    chat_notifications BOOLEAN DEFAULT true,
    match_notifications BOOLEAN DEFAULT true,
    marketing_notifications BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- RLS 활성화
ALTER TABLE blinddate_notification_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their notification settings"
ON blinddate_notification_settings FOR ALL
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());