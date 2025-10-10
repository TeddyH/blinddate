#!/usr/bin/env python3
"""Drop the unused debug_logs table"""

from supabase import create_client, Client

url = "https://dsjzqccyzgyjtchbbruw.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzanpxY2N5emd5anRjaGJicnV3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjgxOTg3NywiZXhwIjoyMDY4Mzk1ODc3fQ.-TWJsDTyQNP0cavogzsI7wTRYdeEuT2kfHR4555Jojk"

supabase: Client = create_client(url, key)

print("="*60)
print("Drop debug_logs Table")
print("="*60)

print("\n⚠️  WARNING: This will permanently delete the debug_logs table!")
print("This table is not used anywhere in the codebase.\n")

response = input("Are you sure you want to drop the debug_logs table? (yes/no): ")

if response.lower() != 'yes':
    print("\n❌ Cancelled. Table not dropped.")
    exit(0)

print("\n[1] Dropping debug_logs table...")

try:
    # Execute DROP TABLE command via RPC or direct SQL
    # Note: Supabase Python client doesn't support direct SQL execution
    # You'll need to run this SQL manually in Supabase SQL Editor:

    sql = "DROP TABLE IF EXISTS debug_logs CASCADE;"

    print(f"\n   📋 Please run this SQL in Supabase SQL Editor:")
    print(f"   " + "-"*56)
    print(f"   {sql}")
    print(f"   " + "-"*56)

    print("\n   Or you can run:")
    print(f"   cat scripts/drop_debug_logs_table.sql | psql [your-connection-string]")

except Exception as e:
    print(f"\n   ❌ Error: {e}")
    exit(1)

print("\n" + "="*60)
print("Instructions provided above")
print("="*60)
