#!/usr/bin/env python3
"""
Manual script to trigger AI response for a specific like
This is a one-time use script to handle the case where:
1. PlutusJ liked Dottie
2. Dottie was then changed to an AI user
3. We need to manually trigger the AI to respond to this like
"""

import os
from supabase import create_client, Client
from datetime import datetime, timezone

# Initialize Supabase client
url = "https://dsjzqccyzgyjtchbbruw.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzanpxY2N5emd5anRjaGJicnV3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjgxOTg3NywiZXhwIjoyMDY4Mzk1ODc3fQ.-TWJsDTyQNP0cavogzsI7wTRYdeEuT2kfHR4555Jojk"

supabase: Client = create_client(url, key)

def main():
    print("=" * 60)
    print("Manual AI Response Trigger for PlutusJ -> Dottie Like")
    print("=" * 60)

    # Step 1: Get user IDs
    print("\n[1] Fetching user information...")
    plutusj = supabase.table('blinddate_users').select('*').eq('nickname', 'PlutusJ').execute()
    dottie = supabase.table('blinddate_users').select('*').eq('nickname', 'Dottie').execute()

    if not plutusj.data or not dottie.data:
        print("❌ Error: Could not find one or both users")
        return

    plutusj_id = plutusj.data[0]['id']
    dottie_id = dottie.data[0]['id']
    is_dottie_ai = dottie.data[0].get('is_ai_user', False)

    print(f"   ✓ PlutusJ ID: {plutusj_id}")
    print(f"   ✓ Dottie ID: {dottie_id}")
    print(f"   ✓ Dottie is AI user: {is_dottie_ai}")

    if not is_dottie_ai:
        print("\n⚠️  Warning: Dottie is not marked as an AI user!")
        response = input("Continue anyway? (y/n): ")
        if response.lower() != 'y':
            return

    # Step 2: Check existing like (user_actions table)
    print("\n[2] Checking existing like in user_actions...")
    action = supabase.table('blinddate_user_actions').select('*').eq('user_id', plutusj_id).eq('target_user_id', dottie_id).eq('action', 'liked').execute()

    if not action.data:
        print("❌ Error: No like found from PlutusJ to Dottie")
        return

    action_data = action.data[0]
    print(f"   ✓ Action ID: {action_data['id']}")
    print(f"   ✓ Action: {action_data['action']}")
    print(f"   ✓ Created at: {action_data['created_at']}")

    # Step 3: Check if already in AI action queue
    print("\n[3] Checking AI action queue...")
    queue = supabase.table('blinddate_ai_action_queue').select('*').eq('ai_user_id', dottie_id).eq('target_user_id', plutusj_id).eq('action_type', 'respond_to_like').execute()

    if queue.data:
        print(f"   ⚠️  Action already exists in queue:")
        for item in queue.data:
            print(f"      - ID: {item['id']}, Status: {item['status']}, Scheduled: {item.get('scheduled_at', 'N/A')}")

        response = input("\nCreate a new queue entry anyway? (y/n): ")
        if response.lower() != 'y':
            print("\nℹ️  You can manually update the existing queue entry if needed")
            return
    else:
        print("   ✓ No existing queue entry found")

    # Step 4: Create AI action queue entry
    print("\n[4] Creating AI action queue entry...")

    queue_entry = {
        'ai_user_id': dottie_id,
        'target_user_id': plutusj_id,
        'action_type': 'respond_to_like',
        'status': 'pending',
        'scheduled_at': datetime.now(timezone.utc).isoformat(),
        'retry_count': 0,
        'action_data': {
            'trigger': 'manual',
            'original_action_id': action_data['id'],
            'manual_trigger': True,
            'reason': 'User converted to AI after receiving like'
        }
    }

    result = supabase.table('blinddate_ai_action_queue').insert(queue_entry).execute()

    if result.data:
        print("   ✅ Successfully created AI action queue entry!")
        print(f"   Queue ID: {result.data[0]['id']}")
        print(f"\n   The AI operation script should process this automatically.")
        print(f"   Check the status with:")
        print(f"   SELECT * FROM blinddate_ai_action_queue WHERE id = '{result.data[0]['id']}';")
    else:
        print("   ❌ Failed to create queue entry")
        print(f"   Error: {result}")

    print("\n" + "=" * 60)
    print("Done!")
    print("=" * 60)

if __name__ == "__main__":
    main()
