#!/usr/bin/env python3
"""Setup AI user settings for Dottie"""

from supabase import create_client, Client

url = "https://dsjzqccyzgyjtchbbruw.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzanpxY2N5emd5anRjaGJicnV3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjgxOTg3NywiZXhwIjoyMDY4Mzk1ODc3fQ.-TWJsDTyQNP0cavogzsI7wTRYdeEuT2kfHR4555Jojk"

supabase: Client = create_client(url, key)

print("="*60)
print("Dottie AI User Settings Setup")
print("="*60)

# Get Dottie's user info
dottie = supabase.table('blinddate_users').select('id, nickname, is_ai_user').eq('nickname', 'Dottie').execute()

if not dottie.data:
    print("❌ Error: Dottie not found")
    exit(1)

dottie_id = dottie.data[0]['id']
is_ai = dottie.data[0]['is_ai_user']

print(f"\n[1] Dottie User Info:")
print(f"   ID: {dottie_id}")
print(f"   Is AI User: {is_ai}")

# Check if settings exist
print(f"\n[2] Checking existing AI settings...")
existing = supabase.table('blinddate_ai_user_settings').select('*').eq('ai_user_id', dottie_id).execute()

if existing.data:
    print(f"   ⚠️  Settings already exist:")
    settings = existing.data[0]
    print(f"      - Response Rate: {settings.get('response_rate', 'N/A')}")
    print(f"      - Min Delay: {settings.get('min_response_delay_minutes', 'N/A')} min")
    print(f"      - Max Delay: {settings.get('max_response_delay_minutes', 'N/A')} min")
    print(f"      - Active Hours: {settings.get('active_hours_start', 'N/A')}:00 - {settings.get('active_hours_end', 'N/A')}:00")
    print(f"      - Is Active: {settings.get('is_active', 'N/A')}")

    response = input("\n   Update to 100% response rate? (y/n): ")
    if response.lower() == 'y':
        print("\n[3] Updating settings...")
        update_data = {
            'response_rate': 1.0,  # 100%
            'is_active': True
        }
        result = supabase.table('blinddate_ai_user_settings').update(update_data).eq('ai_user_id', dottie_id).execute()

        if result.data:
            print("   ✅ Settings updated successfully!")
            print(f"      - Response Rate: 100%")
        else:
            print("   ❌ Failed to update settings")
else:
    print("   ✓ No existing settings found")
    print("\n[3] Creating new AI settings...")

    settings_data = {
        'ai_user_id': dottie_id,
        'min_response_delay_minutes': 1,      # 최소 1분 (빠른 응답)
        'max_response_delay_minutes': 30,     # 최대 30분
        'active_hours_start': 0,              # 24시간 활성
        'active_hours_end': 24,               # 24시간 활성
        'response_rate': 1.0,                 # 100% 응답률
        'chattiness': 0.7,                    # 채팅 활발도 70%
        'llm_temperature': 0.7,               # LLM 창의성
        'is_active': True                     # 활성화
    }

    result = supabase.table('blinddate_ai_user_settings').insert(settings_data).execute()

    if result.data:
        print("   ✅ AI settings created successfully!")
        print(f"      - Response Rate: 100%")
        print(f"      - Response Delay: 1-30 minutes")
        print(f"      - Active Hours: 24/7")
        print(f"      - Chattiness: 70%")
    else:
        print("   ❌ Failed to create settings")
        print(f"   Error: {result}")

print("\n" + "="*60)
print("Done!")
print("="*60)
