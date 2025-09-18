import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client with service role key
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    const now = new Date()
    console.log(`Running match reveal process at ${now.toISOString()}`)

    // 1. Reveal matches that are ready to be revealed
    const { data: revealResult, error: revealError } = await supabase
      .rpc('reveal_scheduled_matches')

    if (revealError) {
      throw new Error(`Failed to reveal matches: ${revealError.message}`)
    }

    const revealedCount = revealResult || 0
    console.log(`Revealed ${revealedCount} matches`)

    // 2. Clean up expired matches
    const { data: cleanupResult, error: cleanupError } = await supabase
      .rpc('cleanup_expired_matches')

    if (cleanupError) {
      throw new Error(`Failed to cleanup expired matches: ${cleanupError.message}`)
    }

    const cleanedUpCount = cleanupResult || 0
    console.log(`Cleaned up ${cleanedUpCount} expired matches`)

    // 3. Send push notifications for newly revealed matches (if configured)
    let notificationsSent = 0
    if (revealedCount > 0) {
      try {
        // Get newly revealed matches to send notifications
        const { data: newlyRevealed } = await supabase
          .from('blinddate_scheduled_matches')
          .select(`
            id,
            user1_id,
            user2_id,
            user1:blinddate_users!user1_id(
              id,
              blinddate_user_profiles!inner(notification_token)
            ),
            user2:blinddate_users!user2_id(
              id,
              blinddate_user_profiles!inner(notification_token)
            )
          `)
          .eq('status', 'revealed')
          .gte('revealed_at', new Date(now.getTime() - 5 * 60 * 1000).toISOString()) // Last 5 minutes

        if (newlyRevealed && newlyRevealed.length > 0) {
          // Here you would integrate with your push notification service
          // For now, we'll just log the intention
          console.log(`Would send notifications for ${newlyRevealed.length} newly revealed matches`)
          notificationsSent = newlyRevealed.length * 2 // Both users in each match
        }
      } catch (notificationError) {
        console.error('Error sending notifications:', notificationError)
        // Don't fail the entire process for notification errors
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Match reveal process completed successfully',
        revealedMatches: revealedCount,
        cleanedUpMatches: cleanedUpCount,
        notificationsSent: notificationsSent,
        processedAt: now.toISOString()
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in match reveal process:', error)

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})