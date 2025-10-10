#!/usr/bin/env python3
"""Analyze chat quality to identify AI-like patterns"""

from supabase import create_client, Client

url = "https://dsjzqccyzgyjtchbbruw.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzanpxY2N5emd5anRjaGJicnV3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjgxOTg3NywiZXhwIjoyMDY4Mzk1ODc3fQ.-TWJsDTyQNP0cavogzsI7wTRYdeEuT2kfHR4555Jojk"

supabase: Client = create_client(url, key)

print("="*70)
print("AI Chat Quality Analysis")
print("="*70)

# Get recent chat rooms with AI users
print("\n[1] Finding chat rooms with AI users...")

chat_rooms = supabase.table('blinddate_chat_rooms').select(
    'id, user1_id, user2_id, created_at'
).order('updated_at', desc=True).limit(5).execute()

print(f"   ✓ Found {len(chat_rooms.data)} recent chat rooms\n")

for room in chat_rooms.data:
    room_id = room['id']

    # Get users info
    user1 = supabase.table('blinddate_users').select('nickname, is_ai_user').eq('id', room['user1_id']).single().execute()
    user2 = supabase.table('blinddate_users').select('nickname, is_ai_user').eq('id', room['user2_id']).single().execute()

    user1_name = user1.data['nickname']
    user2_name = user2.data['nickname']
    user1_is_ai = user1.data['is_ai_user']
    user2_is_ai = user2.data['is_ai_user']

    # Skip if no AI user
    if not user1_is_ai and not user2_is_ai:
        continue

    ai_user = user1_name if user1_is_ai else user2_name
    real_user = user2_name if user1_is_ai else user1_name

    print("="*70)
    print(f"Chat Room: {room_id}")
    print(f"AI User: {ai_user} | Real User: {real_user}")
    print("="*70)

    # Get messages
    messages = supabase.table('blinddate_chat_messages').select(
        'sender_id, message, created_at'
    ).eq('chat_room_id', room_id).order('created_at', desc=False).limit(20).execute()

    if not messages.data:
        print("   (No messages)\n")
        continue

    ai_user_id = room['user1_id'] if user1_is_ai else room['user2_id']

    # Display conversation
    print("\n대화 내용:")
    print("-"*70)

    for i, msg in enumerate(messages.data, 1):
        is_ai = msg['sender_id'] == ai_user_id
        sender = f"[AI] {ai_user}" if is_ai else f"[사람] {real_user}"

        # Mark AI messages
        marker = " ⚠️" if is_ai else ""

        print(f"{i:2}. {sender}: {msg['message']}{marker}")

    print("-"*70)

    # Analyze AI messages
    ai_messages = [m['message'] for m in messages.data if m['sender_id'] == ai_user_id]

    if ai_messages:
        print(f"\n📊 AI 메시지 분석 ({len(ai_messages)}개):")

        # Check for AI-like patterns
        issues = []

        for msg in ai_messages:
            # Too formal
            if any(word in msg for word in ['능력', '범위', '제공', '지원', '시스템']):
                issues.append(f"❌ 너무 형식적: '{msg}'")

            # Too long
            if len(msg) > 30:
                issues.append(f"⚠️  너무 길어요: '{msg}' ({len(msg)}자)")

            # Contains emoji (shouldn't happen but check)
            import re
            if re.search(r'[\U0001F600-\U0001F64F\U0001F300-\U0001F5FF]', msg):
                issues.append(f"❌ 이모지 있음: '{msg}'")

            # Unnatural patterns
            if '죄송합니다' in msg or '말씀드리' in msg:
                issues.append(f"❌ 과도하게 정중: '{msg}'")

            # Good patterns
            if any(pattern in msg for pattern in ['ㅎㅎ', 'ㅋㅋ', '~', '!', '?']):
                pass  # Good, natural

        if issues:
            print("\n   문제점:")
            for issue in issues[:5]:  # Show first 5
                print(f"   {issue}")
        else:
            print("\n   ✅ 특별한 문제점 발견되지 않음")

        # Average length
        avg_length = sum(len(m) for m in ai_messages) / len(ai_messages)
        print(f"\n   평균 길이: {avg_length:.1f}자")

        if avg_length > 25:
            print(f"   ⚠️  평균 메시지가 너무 길어요 (권장: 15-20자)")
        elif avg_length < 10:
            print(f"   ⚠️  평균 메시지가 너무 짧아요")
        else:
            print(f"   ✅ 적절한 길이")

    print("\n")

print("="*70)
print("분석 완료")
print("="*70)
