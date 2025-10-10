#!/usr/bin/env python3
"""Update all AI user settings with complete profile information"""

from supabase import create_client, Client
from datetime import datetime

url = "https://dsjzqccyzgyjtchbbruw.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzanpxY2N5emd5anRjaGJicnV3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjgxOTg3NywiZXhwIjoyMDY4Mzk1ODc3fQ.-TWJsDTyQNP0cavogzsI7wTRYdeEuT2kfHR4555Jojk"

supabase: Client = create_client(url, key)

def calculate_age(birth_date_str):
    """Calculate age from birth date"""
    try:
        birth_date = datetime.strptime(birth_date_str, '%Y-%m-%d')
        today = datetime.now()
        age = today.year - birth_date.year
        if today.month < birth_date.month or (today.month == birth_date.month and today.day < birth_date.day):
            age -= 1
        return age
    except:
        return 25

def generate_system_prompt(user_data):
    """Generate comprehensive system prompt from user data"""

    age = calculate_age(user_data.get('birth_date', '1995-01-01'))
    nickname = user_data.get('nickname', 'Unknown')
    gender = '남성' if user_data.get('gender') == 'male' else '여성'
    bio = user_data.get('bio', '자기소개가 없습니다.')

    # Optional fields
    interests = user_data.get('interests', [])
    interests_str = ', '.join(interests) if interests else '없음'

    mbti = user_data.get('mbti', '없음')
    location = user_data.get('location', '없음')
    job = user_data.get('job_category', '없음')
    personality = user_data.get('personality_traits', [])
    personality_str = ', '.join(personality) if personality else '없음'

    # Create comprehensive system prompt
    system_prompt = f"""당신은 "{nickname}"입니다.
성별: {gender}
나이: {age}세
거주지: {location}
직업: {job}
MBTI: {mbti}
성격: {personality_str}
관심사: {interests_str}
자기소개: {bio}

자연스럽고 진솔한 태도로 대화하세요.
상대방의 프로필을 잘 읽고 진심 어린 판단을 하세요.
당신의 나이, 거주지, 직업, 성격을 고려하여 현실적으로 행동하세요."""

    return system_prompt

print("="*60)
print("Update All AI User Settings")
print("="*60)

# Get all AI users
print("\n[1] Fetching all AI users...")
ai_users = supabase.table('blinddate_users').select('*').eq('is_ai_user', True).execute()

if not ai_users.data:
    print("   ❌ No AI users found")
    exit(1)

print(f"   ✓ Found {len(ai_users.data)} AI users")

# Get existing settings
existing_settings = supabase.table('blinddate_ai_user_settings').select('*').execute()
existing_settings_map = {s['ai_user_id']: s for s in existing_settings.data} if existing_settings.data else {}

print(f"\n[2] Processing AI users...")

updated_count = 0
created_count = 0
errors = []

for user in ai_users.data:
    user_id = user['id']
    nickname = user.get('nickname', 'Unknown')

    try:
        # Generate system prompt
        system_prompt = generate_system_prompt(user)

        # Check if settings exist
        if user_id in existing_settings_map:
            # Update existing settings
            print(f"\n   🔄 Updating: {nickname}")
            print(f"      ID: {user_id}")

            result = supabase.table('blinddate_ai_user_settings').update({
                'llm_system_prompt': system_prompt,
                'response_rate': 0.95  # 95%
            }).eq('ai_user_id', user_id).execute()

            if result.data:
                print(f"      ✅ Updated")
                updated_count += 1
            else:
                print(f"      ❌ Update failed")
                errors.append(f"{nickname}: Update failed")
        else:
            # Create new settings
            print(f"\n   🆕 Creating: {nickname}")
            print(f"      ID: {user_id}")

            settings_data = {
                'ai_user_id': user_id,
                'min_response_delay_minutes': 1,
                'max_response_delay_minutes': 30,
                'active_hours_start': 0,
                'active_hours_end': 24,
                'response_rate': 0.95,  # 95%
                'chattiness': 0.7,
                'llm_temperature': 0.7,
                'llm_system_prompt': system_prompt,
                'is_active': True
            }

            result = supabase.table('blinddate_ai_user_settings').insert(settings_data).execute()

            if result.data:
                print(f"      ✅ Created")
                created_count += 1
            else:
                print(f"      ❌ Creation failed")
                errors.append(f"{nickname}: Creation failed")

        # Show generated prompt preview
        print(f"      📝 Prompt preview:")
        preview = system_prompt.split('\n')[:5]
        for line in preview:
            print(f"         {line}")
        if len(system_prompt.split('\n')) > 5:
            print(f"         ...")

    except Exception as e:
        print(f"   ❌ Error processing {nickname}: {e}")
        errors.append(f"{nickname}: {str(e)}")

print("\n" + "="*60)
print("Summary")
print("="*60)
print(f"Total AI Users: {len(ai_users.data)}")
print(f"Updated: {updated_count}")
print(f"Created: {created_count}")
print(f"Errors: {len(errors)}")

if errors:
    print("\nErrors:")
    for error in errors:
        print(f"  - {error}")

print("\n✅ All AI user settings updated!")
print("   - Response rate: 95%")
print("   - System prompts: Comprehensive profile info included")
print("="*60)
