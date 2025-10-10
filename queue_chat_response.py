#!/usr/bin/env python3
"""Queue chat response for Dottie to reply to PlutusJ's messages"""

from supabase import create_client, Client
from datetime import datetime, timezone

url = "https://dsjzqccyzgyjtchbbruw.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzanpxY2N5emd5anRjaGJicnV3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjgxOTg3NywiZXhwIjoyMDY4Mzk1ODc3fQ.-TWJsDTyQNP0cavogzsI7wTRYdeEuT2kfHR4555Jojk"

supabase: Client = create_client(url, key)

print("="*60)
print("Queue Chat Response for Dottie")
print("="*60)

# Get user IDs
plutusj = supabase.table('blinddate_users').select('id, nickname').eq('nickname', 'PlutusJ').execute()
dottie = supabase.table('blinddate_users').select('id, nickname').eq('nickname', 'Dottie').execute()

plutusj_id = plutusj.data[0]['id']
dottie_id = dottie.data[0]['id']

print(f"\n[1] User IDs:")
print(f"   PlutusJ: {plutusj_id}")
print(f"   Dottie: {dottie_id}")

# Find chat room between them
print(f"\n[2] Finding chat room...")
chatroom = supabase.table('blinddate_chat_rooms').select('*').or_(
    f"and(user1_id.eq.{plutusj_id},user2_id.eq.{dottie_id}),and(user1_id.eq.{dottie_id},user2_id.eq.{plutusj_id})"
).execute()

if not chatroom.data:
    print("   ❌ No chat room found between PlutusJ and Dottie")
    exit(1)

room_id = chatroom.data[0]['id']
print(f"   ✓ Chat Room ID: {room_id}")

# Get recent messages from PlutusJ
print(f"\n[3] Getting recent messages from PlutusJ...")
messages = supabase.table('blinddate_chat_messages').select('*').eq('chat_room_id', room_id).eq('sender_id', plutusj_id).order('created_at', desc=True).limit(10).execute()

if not messages.data:
    print("   ❌ No messages from PlutusJ found")
    exit(1)

print(f"   ✓ Found {len(messages.data)} messages from PlutusJ:")
for i, msg in enumerate(messages.data[:5], 1):
    print(f"      {i}. [{msg['created_at']}] {msg['message'][:50]}...")

# Get Dottie's recent messages to check what she already replied to
dottie_messages = supabase.table('blinddate_chat_messages').select('*').eq('chat_room_id', room_id).eq('sender_id', dottie_id).order('created_at', desc=True).limit(5).execute()

last_dottie_msg_time = None
if dottie_messages.data:
    last_dottie_msg_time = dottie_messages.data[0]['created_at']
    print(f"\n   Dottie's last message: [{last_dottie_msg_time}] {dottie_messages.data[0]['message'][:50]}...")

# Find unanswered messages (messages from PlutusJ after Dottie's last message)
unanswered = []
for msg in messages.data:
    if last_dottie_msg_time is None or msg['created_at'] > last_dottie_msg_time:
        unanswered.append(msg)

if not unanswered:
    print(f"\n   ℹ️  All messages from PlutusJ have been answered")
    print(f"   Creating a new chat response anyway...")
else:
    print(f"\n   ⚠️  Found {len(unanswered)} unanswered message(s) from PlutusJ:")
    for msg in unanswered[:3]:
        print(f"      - [{msg['created_at']}] {msg['message'][:60]}...")

# Check existing pending queue items
print(f"\n[4] Checking existing queue...")
existing_queue = supabase.table('blinddate_ai_action_queue').select('*').eq('ai_user_id', dottie_id).eq('target_user_id', plutusj_id).eq('action_type', 'send_chat_message').eq('status', 'pending').execute()

if existing_queue.data:
    print(f"   ⚠️  Found {len(existing_queue.data)} pending chat message(s) in queue")
    for item in existing_queue.data:
        print(f"      - ID: {item['id']}, Scheduled: {item.get('scheduled_at', 'N/A')}")

# Create new queue entry
print(f"\n[5] Creating AI action queue entry for chat response...")

# Schedule immediately (or with a small delay)
scheduled_time = datetime.now(timezone.utc)

queue_entry = {
    'ai_user_id': dottie_id,
    'target_user_id': plutusj_id,
    'action_type': 'send_chat_message',
    'status': 'pending',
    'scheduled_at': scheduled_time.isoformat(),
    'retry_count': 0,
    'action_data': {
        'trigger': 'manual',
        'room_id': room_id,
        'reason': 'Manual trigger to respond to PlutusJ messages',
        'unanswered_count': len(unanswered) if unanswered else 0
    }
}

result = supabase.table('blinddate_ai_action_queue').insert(queue_entry).execute()

if result.data:
    print("   ✅ Successfully created AI action queue entry!")
    print(f"   Queue ID: {result.data[0]['id']}")
    print(f"   Scheduled: {scheduled_time.isoformat()}")
    print(f"\n   The AI scheduler will process this and generate a response.")
else:
    print("   ❌ Failed to create queue entry")
    print(f"   Error: {result}")

print("\n" + "="*60)
print("Done!")
print("="*60)
