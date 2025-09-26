-- 채팅 테이블명에 prefix 추가
-- chat_rooms -> blinddate_chat_rooms
-- chat_messages -> blinddate_chat_messages

-- 1. 테이블명 변경
ALTER TABLE chat_rooms RENAME TO blinddate_chat_rooms;
ALTER TABLE chat_messages RENAME TO blinddate_chat_messages;

-- 2. 외래 키 제약 조건이 있다면 자동으로 업데이트됨
-- 하지만 혹시 문제가 있을 경우를 대비해 확인용 쿼리들:

-- 외래 키 제약 조건 확인
SELECT
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.table_name IN ('blinddate_chat_rooms', 'blinddate_chat_messages');

-- 인덱스 확인 (자동으로 이름이 변경되어야 함)
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename IN ('blinddate_chat_rooms', 'blinddate_chat_messages');

-- 변경 완료 확인
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name LIKE '%chat_%'
ORDER BY table_name;