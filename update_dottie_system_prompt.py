#!/usr/bin/env python3
"""Update Dottie's system prompt based on other AI users"""

from supabase import create_client, Client

url = "https://dsjzqccyzgyjtchbbruw.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzanpxY2N5emd5anRjaGJicnV3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjgxOTg3NywiZXhwIjoyMDY4Mzk1ODc3fQ.-TWJsDTyQNP0cavogzsI7wTRYdeEuT2kfHR4555Jojk"

supabase: Client = create_client(url, key)

print("="*60)
print("Checking AI User Settings")
print("="*60)

# Get all AI users
ai_users = supabase.table('blinddate_users').select('*').eq('is_ai_user', True).execute()

print(f"\n[1] Found {len(ai_users.data)} AI users")

# Get all AI settings
ai_settings = supabase.table('blinddate_ai_user_settings').select('*').execute()

print(f"\n[2] Checking existing AI settings...")
for setting in ai_settings.data:
    # Find corresponding user
    user = next((u for u in ai_users.data if u['id'] == setting['ai_user_id']), None)
    nickname = user['nickname'] if user else 'Unknown'

    print(f"\n   User: {nickname}")
    print(f"   AI User ID: {setting['ai_user_id']}")
    print(f"   Response Rate: {setting.get('response_rate', 'N/A')}")

    if setting.get('llm_system_prompt'):
        print(f"   System Prompt:")
        print(f"   {setting['llm_system_prompt'][:200]}..." if len(setting['llm_system_prompt']) > 200 else f"   {setting['llm_system_prompt']}")
    else:
        print(f"   System Prompt: [NOT SET]")

# Get Dottie's info
dottie = supabase.table('blinddate_users').select('*').eq('nickname', 'Dottie').execute()

if not dottie.data:
    print("\n❌ Error: Dottie not found")
    exit(1)

dottie_data = dottie.data[0]
dottie_id = dottie_data['id']

print(f"\n" + "="*60)
print(f"[3] Dottie's Profile Info:")
print(f"="*60)
print(f"   Nickname: {dottie_data.get('nickname', 'N/A')}")
print(f"   Birth Date: {dottie_data.get('birth_date', 'N/A')}")
print(f"   Gender: {dottie_data.get('gender', 'N/A')}")
print(f"   Bio: {dottie_data.get('bio', 'N/A')}")
print(f"   Interests: {dottie_data.get('interests', 'N/A')}")
print(f"   MBTI: {dottie_data.get('mbti', 'N/A')}")
print(f"   Location: {dottie_data.get('location', 'N/A')}")
print(f"   Job: {dottie_data.get('job_category', 'N/A')}")
print(f"   Personality: {dottie_data.get('personality_traits', 'N/A')}")

# Calculate age from birth_date
from datetime import datetime
birth_date = dottie_data.get('birth_date')
if birth_date:
    birth_year = int(birth_date.split('-')[0])
    age = datetime.now().year - birth_year
else:
    age = 25

# Create system prompt for Dottie based on her profile
system_prompt = f"""You are {dottie_data.get('nickname', 'Dottie')}, a {age}-year-old {dottie_data.get('gender', 'female')} on a dating app.

Your personality and background:
- Bio: {dottie_data.get('bio', 'A friendly and outgoing person looking for meaningful connections.')}
- Interests: {dottie_data.get('interests', ['traveling', 'reading', 'coffee'])}
- MBTI: {dottie_data.get('mbti', 'ENFP')}
- Location: {dottie_data.get('location', 'Seoul, Korea')}

When deciding whether to like someone back or respond to messages:
1. Consider if their profile aligns with your interests and values
2. Look for genuine connection potential based on their bio and interests
3. Be authentic and true to your personality type ({dottie_data.get('mbti', 'ENFP')})
4. Respond naturally and conversationally, as a real person would

When chatting:
- Be warm, friendly, and genuine
- Show interest in getting to know the other person
- Share relevant details about yourself based on your bio and interests
- Keep responses natural and conversational (not too long or formal)
- Use casual language appropriate for a dating app

Remember: You're looking for meaningful connections, so be selective but open-minded."""

print(f"\n" + "="*60)
print(f"[4] Generated System Prompt:")
print(f"="*60)
print(system_prompt)

response = input("\n\nUpdate Dottie's system prompt with this? (y/n): ")
if response.lower() == 'y':
    print("\n[5] Updating system prompt...")

    result = supabase.table('blinddate_ai_user_settings').update({
        'llm_system_prompt': system_prompt
    }).eq('ai_user_id', dottie_id).execute()

    if result.data:
        print("   ✅ System prompt updated successfully!")
    else:
        print("   ❌ Failed to update system prompt")
        print(f"   Error: {result}")
else:
    print("\n   Cancelled")

print("\n" + "="*60)
print("Done!")
print("="*60)
