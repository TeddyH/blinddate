#!/usr/bin/env python3
"""Update AI user response rates with random values"""

from supabase import create_client, Client
import random

url = "https://dsjzqccyzgyjtchbbruw.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzanpxY2N5emd5anRjaGJicnV3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjgxOTg3NywiZXhwIjoyMDY4Mzk1ODc3fQ.-TWJsDTyQNP0cavogzsI7wTRYdeEuT2kfHR4555Jojk"

supabase: Client = create_client(url, key)

print("="*60)
print("Update AI Response Rates")
print("="*60)

# Get all AI user settings
print("\n[1] Fetching all AI user settings...")
settings = supabase.table('blinddate_ai_user_settings').select('*').execute()

if not settings.data:
    print("   ❌ No AI user settings found")
    exit(1)

print(f"   ✓ Found {len(settings.data)} AI user settings")

# Get user nicknames
user_ids = [s['ai_user_id'] for s in settings.data]
users = supabase.table('blinddate_users').select('id, nickname').in_('id', user_ids).execute()
user_map = {u['id']: u['nickname'] for u in users.data}

print(f"\n[2] Updating response rates and chattiness...")

updated_count = 0
errors = []

for setting in settings.data:
    user_id = setting['ai_user_id']
    nickname = user_map.get(user_id, 'Unknown')

    try:
        # Generate random values
        # response_rate: 0.4 ~ 0.7
        response_rate = round(random.uniform(0.4, 0.7), 2)

        # chattiness: 0.9 ~ 0.95
        chattiness = round(random.uniform(0.9, 0.95), 2)

        print(f"\n   🔄 Updating: {nickname}")
        print(f"      User ID: {user_id}")
        print(f"      Response Rate: {response_rate} (LIKE 응답 확률)")
        print(f"      Chattiness: {chattiness} (채팅 응답 확률)")

        # Update settings
        result = supabase.table('blinddate_ai_user_settings').update({
            'response_rate': response_rate,
            'chattiness': chattiness
        }).eq('ai_user_id', user_id).execute()

        if result.data:
            print(f"      ✅ Updated")
            updated_count += 1
        else:
            print(f"      ❌ Update failed")
            errors.append(f"{nickname}: Update failed")

    except Exception as e:
        print(f"   ❌ Error processing {nickname}: {e}")
        errors.append(f"{nickname}: {str(e)}")

print("\n" + "="*60)
print("Summary")
print("="*60)
print(f"Total AI Users: {len(settings.data)}")
print(f"Updated: {updated_count}")
print(f"Errors: {len(errors)}")

if errors:
    print("\nErrors:")
    for error in errors:
        print(f"  - {error}")

print("\n✅ All AI user settings updated!")
print(f"   - Response Rate: 0.4 ~ 0.7 (랜덤)")
print(f"   - Chattiness: 0.9 ~ 0.95 (랜덤)")
print("="*60)
