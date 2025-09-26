-- Supabase Realtime 연결 및 권한 테스트 쿼리들

-- 1. Realtime이 활성화된 테이블 목록 확인
SELECT schemaname, tablename
FROM pg_catalog.pg_publication_tables
WHERE pubname = 'supabase_realtime';

-- 2. 채팅 테이블들의 RLS 상태 확인
SELECT tablename, rowsecurity, hasoids
FROM pg_tables
WHERE tablename IN ('blinddate_chat_rooms', 'blinddate_chat_messages');

-- 3. 현재 RLS 정책들 확인
SELECT tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename IN ('blinddate_chat_rooms', 'blinddate_chat_messages')
ORDER BY tablename, policyname;

-- 4. 테이블 구조 확인
\d blinddate_chat_messages;
\d blinddate_chat_rooms;

-- 5. 샘플 데이터 확인 (현재 사용자의 채팅방만)
SELECT cr.id, cr.user1_id, cr.user2_id, cr.last_message, cr.created_at
FROM blinddate_chat_rooms cr
WHERE cr.user1_id = auth.uid() OR cr.user2_id = auth.uid()
ORDER BY cr.updated_at DESC
LIMIT 5;

-- 6. 최근 메시지 확인
SELECT cm.id, cm.chat_room_id, cm.sender_id, cm.message, cm.created_at
FROM blinddate_chat_messages cm
JOIN blinddate_chat_rooms cr ON cm.chat_room_id = cr.id
WHERE cr.user1_id = auth.uid() OR cr.user2_id = auth.uid()
ORDER BY cm.created_at DESC
LIMIT 10;