#!/usr/bin/env python3
"""Auto-update Dottie's system prompt"""

from supabase import create_client, Client

url = "https://dsjzqccyzgyjtchbbruw.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzanpxY2N5emd5anRjaGJicnV3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjgxOTg3NywiZXhwIjoyMDY4Mzk1ODc3fQ.-TWJsDTyQNP0cavogzsI7wTRYdeEuT2kfHR4555Jojk"

supabase: Client = create_client(url, key)

print("="*60)
print("Auto-updating Dottie's System Prompt")
print("="*60)

# Get Dottie's info
dottie = supabase.table('blinddate_users').select('*').eq('nickname', 'Dottie').execute()

if not dottie.data:
    print("\n❌ Error: Dottie not found")
    exit(1)

dottie_data = dottie.data[0]
dottie_id = dottie_data['id']

print(f"\n[1] Dottie's Profile:")
print(f"   Nickname: {dottie_data.get('nickname')}")
print(f"   Gender: {dottie_data.get('gender')}")
print(f"   Bio: {dottie_data.get('bio')}")

# Create system prompt in Korean style (matching other AI users)
system_prompt = f"""당신은 "{dottie_data.get('nickname')}"입니다.
성별: {dottie_data.get('gender')}
자기소개: {dottie_data.get('bio')}

자연스럽고 진솔한 태도로 대화하세요.
상대방의 프로필을 잘 읽고 진심 어린 판단을 하세요."""

print(f"\n[2] Generated System Prompt:")
print("-" * 60)
print(system_prompt)
print("-" * 60)

print(f"\n[3] Updating system prompt...")
result = supabase.table('blinddate_ai_user_settings').update({
    'llm_system_prompt': system_prompt
}).eq('ai_user_id', dottie_id).execute()

if result.data:
    print("   ✅ System prompt updated successfully!")
else:
    print("   ❌ Failed to update system prompt")
    print(f"   Error: {result}")

print("\n" + "="*60)
print("Done!")
print("="*60)
