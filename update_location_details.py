#!/usr/bin/env python3
"""Update AI user settings with specific city information"""

from supabase import create_client, Client
from datetime import datetime
import random

url = "https://dsjzqccyzgyjtchbbruw.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzanpxY2N5emd5anRjaGJicnV3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjgxOTg3NywiZXhwIjoyMDY4Mzk1ODc3fQ.-TWJsDTyQNP0cavogzsI7wTRYdeEuT2kfHR4555Jojk"

supabase: Client = create_client(url, key)

# City mappings
CITY_MAPPING = {
    '경기 남부': ['수원', '성남', '용인', '안양', '부천', '광명', '과천', '의왕', '군포', '안산'],
    '경기 북부': ['고양', '파주', '의정부', '양주', '동두천', '포천', '연천', '남양주', '구리'],
    '서울': None,  # 서울은 이미 구체적
    '인천': None,  # 인천도 이미 구체적
}

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

def enhance_location(location):
    """Add specific city to general location"""
    if not location:
        return '서울'

    for region, cities in CITY_MAPPING.items():
        if region in location and cities:
            # Pick a random city from the list
            city = random.choice(cities)
            return f"{region} {city}"

    return location

def generate_system_prompt(user_data, enhanced_location):
    """Generate comprehensive system prompt with enhanced location"""

    age = calculate_age(user_data.get('birth_date', '1995-01-01'))
    nickname = user_data.get('nickname', 'Unknown')
    gender = '남성' if user_data.get('gender') == 'male' else '여성'
    bio = user_data.get('bio', '자기소개가 없습니다.')

    # Optional fields
    interests = user_data.get('interests', [])
    interests_str = ', '.join(interests) if interests else '없음'

    mbti = user_data.get('mbti', '없음')
    job = user_data.get('job_category', '없음')
    personality = user_data.get('personality_traits', [])
    personality_str = ', '.join(personality) if personality else '없음'

    # Create comprehensive system prompt with enhanced location
    system_prompt = f"""당신은 "{nickname}"입니다.
성별: {gender}
나이: {age}세
거주지: {enhanced_location}
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
print("Update Location Details for AI Users")
print("="*60)

# Get all AI users
print("\n[1] Fetching all AI users...")
ai_users = supabase.table('blinddate_users').select('*').eq('is_ai_user', True).execute()

if not ai_users.data:
    print("   ❌ No AI users found")
    exit(1)

print(f"   ✓ Found {len(ai_users.data)} AI users")

print(f"\n[2] Processing AI users with vague locations...")

updated_count = 0
skipped_count = 0
errors = []

for user in ai_users.data:
    user_id = user['id']
    nickname = user.get('nickname', 'Unknown')
    original_location = user.get('location', '서울')

    # Check if location needs enhancement
    needs_update = False
    for region in ['경기 남부', '경기 북부']:
        if region in original_location and not any(city in original_location for city in CITY_MAPPING.get(region, [])):
            needs_update = True
            break

    if not needs_update:
        print(f"\n   ⏭️  Skipping: {nickname} (location: {original_location})")
        skipped_count += 1
        continue

    try:
        # Enhance location
        enhanced_location = enhance_location(original_location)

        print(f"\n   🔄 Updating: {nickname}")
        print(f"      Original: {original_location}")
        print(f"      Enhanced: {enhanced_location}")

        # Generate new system prompt with enhanced location
        system_prompt = generate_system_prompt(user, enhanced_location)

        # Update settings
        result = supabase.table('blinddate_ai_user_settings').update({
            'llm_system_prompt': system_prompt
        }).eq('ai_user_id', user_id).execute()

        if result.data:
            print(f"      ✅ Updated")
            updated_count += 1

            # Show prompt preview
            print(f"      📝 Prompt preview:")
            preview = system_prompt.split('\n')[:5]
            for line in preview:
                print(f"         {line}")
        else:
            print(f"      ❌ Update failed")
            errors.append(f"{nickname}: Update failed")

    except Exception as e:
        print(f"   ❌ Error processing {nickname}: {e}")
        errors.append(f"{nickname}: {str(e)}")

print("\n" + "="*60)
print("Summary")
print("="*60)
print(f"Total AI Users: {len(ai_users.data)}")
print(f"Updated: {updated_count}")
print(f"Skipped (already specific): {skipped_count}")
print(f"Errors: {len(errors)}")

if errors:
    print("\nErrors:")
    for error in errors:
        print(f"  - {error}")

print("\n✅ Location details updated!")
print("="*60)
