#!/usr/bin/env python3
"""Quick script to check the current state of likes/actions"""

from supabase import create_client, Client

url = "https://dsjzqccyzgyjtchbbruw.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzanpxY2N5emd5anRjaGJicnV3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjgxOTg3NywiZXhwIjoyMDY4Mzk1ODc3fQ.-TWJsDTyQNP0cavogzsI7wTRYdeEuT2kfHR4555Jojk"

supabase: Client = create_client(url, key)

# Get user IDs
plutusj = supabase.table('blinddate_users').select('id, nickname').eq('nickname', 'PlutusJ').execute()
dottie = supabase.table('blinddate_users').select('id, nickname').eq('nickname', 'Dottie').execute()

plutusj_id = plutusj.data[0]['id']
dottie_id = dottie.data[0]['id']

print(f"PlutusJ ID: {plutusj_id}")
print(f"Dottie ID: {dottie_id}")
print("\n" + "="*60)

# Check all actions from PlutusJ
print("\n[1] All actions FROM PlutusJ:")
actions_from = supabase.table('blinddate_user_actions').select('*').eq('user_id', plutusj_id).execute()
if actions_from.data:
    for action in actions_from.data:
        print(f"   - To: {action['target_user_id']}, Action: {action['action']}, Created: {action['created_at']}")
else:
    print("   No actions found")

# Check all actions TO Dottie
print("\n[2] All actions TO Dottie:")
actions_to = supabase.table('blinddate_user_actions').select('*').eq('target_user_id', dottie_id).execute()
if actions_to.data:
    for action in actions_to.data:
        print(f"   - From: {action['user_id']}, Action: {action['action']}, Created: {action['created_at']}")
else:
    print("   No actions found")

# Check all actions FROM Dottie
print("\n[3] All actions FROM Dottie:")
actions_from_dottie = supabase.table('blinddate_user_actions').select('*').eq('user_id', dottie_id).execute()
if actions_from_dottie.data:
    for action in actions_from_dottie.data:
        print(f"   - To: {action['target_user_id']}, Action: {action['action']}, Created: {action['created_at']}")
else:
    print("   No actions found")

# Check AI action queue
print("\n[4] AI Action Queue for Dottie:")
queue = supabase.table('blinddate_ai_action_queue').select('*').eq('ai_user_id', dottie_id).execute()
if queue.data:
    for item in queue.data:
        print(f"   - ID: {item['id']}")
        print(f"     Target: {item['target_user_id']}")
        print(f"     Type: {item['action_type']}")
        print(f"     Status: {item['status']}")
        print(f"     Scheduled: {item.get('scheduled_at', 'N/A')}")
        print()
else:
    print("   No queue entries found")

print("="*60)
