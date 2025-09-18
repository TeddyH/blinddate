import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
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
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    console.log('Starting Hearty daily batch matching process...')

    const today = new Date()
    const kstOffset = 9 * 60 * 60 * 1000
    const kstDate = new Date(today.getTime() + kstOffset)
    const todayStr = kstDate.toISOString().split('T')[0]

    const revealTime = new Date(kstDate)
    revealTime.setHours(12, 0, 0, 0)

    const expiresTime = new Date(kstDate)
    expiresTime.setHours(23, 59, 0, 0)

    console.log('Match date:', todayStr)
    console.log('Reveal time:', revealTime.toISOString())
    console.log('Expires time:', expiresTime.toISOString())

    const { data: maleUsers, error: maleError } = await supabaseClient
      .from('blinddate_users')
      .select('id')
      .eq('approval_status', 'approved')
      .eq('country', 'KR')
      .eq('gender', 'male')

    if (maleError) {
      console.error('Error fetching male users:', maleError)
      throw maleError
    }

    const { data: femaleUsers, error: femaleError } = await supabaseClient
      .from('blinddate_users')
      .select('id')
      .eq('approval_status', 'approved')
      .eq('country', 'KR')
      .eq('gender', 'female')

    if (femaleError) {
      console.error('Error fetching female users:', femaleError)
      throw femaleError
    }

    const maleCount = maleUsers?.length || 0
    const femaleCount = femaleUsers?.length || 0

    console.log('Male users:', maleCount, 'Female users:', femaleCount)

    if (maleCount === 0 || femaleCount === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          message: 'No eligible users found for matching',
          matches_created: 0
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200
        }
      )
    }

    const shuffledMales = maleUsers.sort(() => Math.random() - 0.5)
    const shuffledFemales = femaleUsers.sort(() => Math.random() - 0.5)

    // Create only 1 match per day (not all possible matches)
    const maxDailyMatches = 1
    const matchCount = Math.min(maleCount, femaleCount, maxDailyMatches)
    const matches = []

    for (let i = 0; i < matchCount; i++) {
      const maleId = shuffledMales[i].id
      const femaleId = shuffledFemales[i].id

      const user1Id = maleId < femaleId ? maleId : femaleId
      const user2Id = maleId < femaleId ? femaleId : maleId

      // Check if reveal time has passed
      const now = new Date()
      const shouldReveal = now >= revealTime

      matches.push({
        user1_id: user1Id,
        user2_id: user2Id,
        match_date: todayStr,
        reveal_time: revealTime.toISOString(),
        expires_at: expiresTime.toISOString(),
        status: shouldReveal ? 'revealed' : 'pending',
        revealed_at: shouldReveal ? revealTime.toISOString() : null
      })
    }

    const { data: insertedMatches, error: matchError } = await supabaseClient
      .from('blinddate_scheduled_matches')
      .upsert(matches, {
        onConflict: 'user1_id,user2_id,match_date',
        ignoreDuplicates: true
      })

    if (matchError) {
      console.error('Error creating matches:', matchError)
      throw matchError
    }

    const { error: logError } = await supabaseClient
      .from('blinddate_daily_match_processing')
      .upsert({
        process_date: todayStr,
        started_at: new Date().toISOString(),
        completed_at: new Date().toISOString(),
        total_eligible_users: maleCount + femaleCount,
        total_matches_created: matchCount,
        status: 'completed'
      }, {
        onConflict: 'process_date'
      })

    if (logError) {
      console.error('Error logging batch process:', logError)
    }

    console.log('Batch matching completed. Created', matchCount, 'matches.')

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Batch matching completed successfully',
        matches_created: matchCount,
        male_users: maleCount,
        female_users: femaleCount,
        match_date: todayStr,
        reveal_time: revealTime.toISOString()
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      }
    )

  } catch (error) {
    console.error('Error in batch matching:', error)

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500
      }
    )
  }
})
