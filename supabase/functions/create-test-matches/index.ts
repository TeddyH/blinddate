import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const today = new Date().toISOString().split('T')[0]
    const revealTime = new Date()
    revealTime.setHours(12, 0, 0, 0) // Set to noon today
    const expiresTime = new Date()
    expiresTime.setHours(23, 59, 0, 0) // Set to end of today

    console.log('Creating test matches for date:', today)
    console.log('Reveal time:', revealTime.toISOString())
    console.log('Expires time:', expiresTime.toISOString())

    // Get approved users
    const { data: users, error: usersError } = await supabaseClient
      .from('blinddate_users')
      .select('id, gender')
      .eq('approval_status', 'approved')
      .eq('country', 'KR')

    if (usersError) {
      throw new Error(`Failed to fetch users: ${usersError.message}`)
    }

    console.log('Found users:', users.length)

    const maleUsers = users.filter(u => u.gender === 'male')
    const femaleUsers = users.filter(u => u.gender === 'female')

    console.log('Male users:', maleUsers.length)
    console.log('Female users:', femaleUsers.length)

    // Create matches
    const matches = []
    const matchCount = Math.min(maleUsers.length, femaleUsers.length)

    for (let i = 0; i < matchCount; i++) {
      const maleId = maleUsers[i].id
      const femaleId = femaleUsers[i].id

      // Ensure user1_id < user2_id for constraint
      const user1Id = maleId < femaleId ? maleId : femaleId
      const user2Id = maleId < femaleId ? femaleId : maleId

      matches.push({
        user1_id: user1Id,
        user2_id: user2Id,
        match_date: today,
        reveal_time: revealTime.toISOString(),
        expires_at: expiresTime.toISOString(),
        status: 'revealed',
        revealed_at: revealTime.toISOString()
      })
    }

    console.log('Creating matches:', matches.length)

    // Insert matches (this will use service role key to bypass RLS)
    const { data: insertedMatches, error: matchError } = await supabaseClient
      .from('blinddate_scheduled_matches')
      .upsert(matches, { onConflict: 'user1_id,user2_id,match_date' })
      .select()

    if (matchError) {
      throw new Error(`Failed to create matches: ${matchError.message}`)
    }

    console.log('Inserted matches:', insertedMatches?.length || 0)

    // Record processing log
    const { error: logError } = await supabaseClient
      .from('blinddate_daily_match_processing')
      .upsert({
        process_date: today,
        started_at: new Date().toISOString(),
        completed_at: new Date().toISOString(),
        total_eligible_users: users.length,
        total_matches_created: matches.length,
        status: 'completed'
      }, { onConflict: 'process_date' })

    if (logError) {
      console.error('Failed to create processing log:', logError.message)
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `Created ${matches.length} matches for ${today}`,
        data: {
          total_users: users.length,
          male_users: maleUsers.length,
          female_users: femaleUsers.length,
          matches_created: matches.length,
          matches: insertedMatches
        }
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    console.error('Error creating test matches:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})