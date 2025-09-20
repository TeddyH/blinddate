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

    const expiresTime = new Date(kstDate)
    expiresTime.setHours(23, 59, 0, 0)

    console.log('Match date:', todayStr)
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

    // Get all past matches to avoid duplicates
    console.log('Fetching past matches to avoid duplicates...')
    const { data: pastMatches, error: pastMatchesError } = await supabaseClient
      .from('blinddate_scheduled_matches')
      .select('user1_id, user2_id')

    if (pastMatchesError) {
      console.error('Error fetching past matches:', pastMatchesError)
      throw pastMatchesError
    }

    console.log('Past matches count:', pastMatches?.length || 0)

    // Create set of forbidden pairs
    const forbiddenPairs = new Set()
    if (pastMatches) {
      pastMatches.forEach(match => {
        const pair = [match.user1_id, match.user2_id].sort().join('|')
        forbiddenPairs.add(pair)
      })
    }

    console.log('Forbidden pairs count:', forbiddenPairs.size)

    // Generate all possible valid matches
    const possibleMatches = []
    for (const male of maleUsers) {
      for (const female of femaleUsers) {
        const pair = [male.id, female.id].sort().join('|')
        if (!forbiddenPairs.has(pair)) {
          possibleMatches.push({
            maleId: male.id,
            femaleId: female.id
          })
        }
      }
    }

    console.log('Possible new matches count:', possibleMatches.length)

    if (possibleMatches.length === 0) {
      console.log('No new matches available - all combinations have been used')
      return new Response(
        JSON.stringify({
          success: true,
          message: 'No new matches available - all combinations have been used',
          matches_created: 0,
          male_users: maleCount,
          female_users: femaleCount,
          possible_matches: 0
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200
        }
      )
    }

    // Shuffle possible matches and select as many as we can
    const shuffledPossibleMatches = possibleMatches.sort(() => Math.random() - 0.5)
    const maxDailyMatches = Math.min(maleCount, femaleCount, possibleMatches.length)
    const matchCount = maxDailyMatches
    const matches = []

    // Create matches ensuring no user appears twice
    const usedMales = new Set()
    const usedFemales = new Set()

    for (const possibleMatch of shuffledPossibleMatches) {
      if (matches.length >= matchCount) break

      if (!usedMales.has(possibleMatch.maleId) && !usedFemales.has(possibleMatch.femaleId)) {
        usedMales.add(possibleMatch.maleId)
        usedFemales.add(possibleMatch.femaleId)

        const user1Id = possibleMatch.maleId < possibleMatch.femaleId ? possibleMatch.maleId : possibleMatch.femaleId
        const user2Id = possibleMatch.maleId < possibleMatch.femaleId ? possibleMatch.femaleId : possibleMatch.maleId

        matches.push({
          user1_id: user1Id,
          user2_id: user2Id,
          match_date: todayStr,
          expires_at: expiresTime.toISOString(),
          status: 'revealed'
        })
      }
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
        possible_matches: possibleMatches.length,
        forbidden_pairs: forbiddenPairs.size
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
