#!/usr/bin/env python3
"""Check if chattiness is being used by examining AI action queue data"""

from supabase import create_client, Client

url = "https://dsjzqccyzgyjtchbbruw.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzanpxY2N5emd5anRjaGJicnV3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjgxOTg3NywiZXhwIjoyMDY4Mzk1ODc3fQ.-TWJsDTyQNP0cavogzsI7wTRYdeEuT2kfHR4555Jojk"

supabase: Client = create_client(url, key)

print("="*60)
print("Chattiness Usage Check")
print("="*60)

# 1. Check if trigger exists
print("\n[1] Checking if chat response trigger exists...")
print("    SQL Query to run in Supabase:")
print("    " + "-"*56)
print("""    SELECT
      trigger_name,
      event_object_table,
      action_statement
    FROM information_schema.triggers
    WHERE trigger_name = 'on_chat_message_schedule_ai_response';""")
print("    " + "-"*56)

# 2. Check recent chat messages and corresponding queue entries
print("\n[2] Checking recent AI chat message queue entries...")
print("    This will show if chattiness is being recorded in action_data")
print()

# Get recent chat message actions
recent_actions = supabase.table('blinddate_ai_action_queue').select(
    'id, ai_user_id, action_type, action_data, status, scheduled_at, created_at'
).eq('action_type', 'send_chat_message').order('created_at', desc=True).limit(10).execute()

if not recent_actions.data:
    print("    ❌ No chat message actions found in queue")
else:
    print(f"    ✓ Found {len(recent_actions.data)} recent chat message actions\n")

    # Get AI user nicknames
    ai_user_ids = [a['ai_user_id'] for a in recent_actions.data]
    users = supabase.table('blinddate_users').select('id, nickname').in_('id', ai_user_ids).execute()
    user_map = {u['id']: u['nickname'] for u in users.data}

    for i, action in enumerate(recent_actions.data, 1):
        nickname = user_map.get(action['ai_user_id'], 'Unknown')
        action_data = action.get('action_data', {})

        print(f"    [{i}] AI User: {nickname}")
        print(f"        Queue ID: {action['id']}")
        print(f"        Status: {action['status']}")
        print(f"        Created: {action['created_at']}")

        # Check if chattiness is in action_data
        if 'chattiness' in action_data:
            print(f"        ✅ Chattiness: {action_data['chattiness']} (RECORDED IN QUEUE)")
        else:
            print(f"        ❌ Chattiness: NOT FOUND in action_data")

        if 'chat_room_id' in action_data:
            print(f"        Chat Room: {action_data['chat_room_id']}")

        if 'trigger_message' in action_data:
            msg = action_data['trigger_message']
            print(f"        Trigger Message: {msg[:50]}...")

        print()

# 3. Statistics: How many messages were ignored due to chattiness
print("\n[3] Checking chattiness effectiveness...")
print("    To check if messages are being ignored due to chattiness:")
print("    " + "-"*56)
print("""    -- Count total messages sent TO AI users
    SELECT COUNT(*) as total_messages_to_ai
    FROM blinddate_chat_messages cm
    JOIN blinddate_chat_rooms cr ON cm.chat_room_id = cr.id
    JOIN blinddate_users u ON (
      CASE
        WHEN cr.user1_id = cm.sender_id THEN cr.user2_id
        ELSE cr.user1_id
      END = u.id
    )
    WHERE u.is_ai_user = TRUE
      AND cm.created_at > NOW() - INTERVAL '24 hours';

    -- Count how many AI responses were queued
    SELECT COUNT(*) as ai_responses_queued
    FROM blinddate_ai_action_queue
    WHERE action_type = 'send_chat_message'
      AND created_at > NOW() - INTERVAL '24 hours';""")
print("    " + "-"*56)

# 4. Get AI settings to see current chattiness values
print("\n[4] Current chattiness settings for AI users...")

settings = supabase.table('blinddate_ai_user_settings').select(
    'ai_user_id, chattiness'
).execute()

if settings.data:
    # Get user nicknames
    user_ids = [s['ai_user_id'] for s in settings.data]
    users = supabase.table('blinddate_users').select('id, nickname').in_('id', user_ids).execute()
    user_map = {u['id']: u['nickname'] for u in users.data}

    # Sort by chattiness
    sorted_settings = sorted(settings.data, key=lambda x: x.get('chattiness', 0), reverse=True)

    print(f"\n    Top 10 most chatty AI users:")
    for i, s in enumerate(sorted_settings[:10], 1):
        nickname = user_map.get(s['ai_user_id'], 'Unknown')
        chattiness = s.get('chattiness', 0)
        print(f"    {i:2}. {nickname:15} - Chattiness: {chattiness:.2f} ({int(chattiness*100)}% response rate)")

    print(f"\n    Bottom 5 least chatty AI users:")
    for i, s in enumerate(sorted_settings[-5:], 1):
        nickname = user_map.get(s['ai_user_id'], 'Unknown')
        chattiness = s.get('chattiness', 0)
        print(f"    {i:2}. {nickname:15} - Chattiness: {chattiness:.2f} ({int(chattiness*100)}% response rate)")

print("\n" + "="*60)
print("Summary")
print("="*60)
print("""
To verify chattiness is working:
1. Check if trigger exists (query above)
2. Check if action_data contains 'chattiness' field
3. Send messages to AI users and see if some are ignored
4. Compare: messages_to_ai vs ai_responses_queued
   - If chattiness = 0.9, roughly 90% should be queued
   - If chattiness = 0.95, roughly 95% should be queued
""")
print("="*60)
