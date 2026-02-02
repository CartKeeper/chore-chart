// Supabase Edge Function to send push notifications for reminders
// Deploy with: supabase functions deploy send-reminders

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import webpush from 'npm:web-push@3.6.7'

// VAPID keys - the private key should be set as a secret
const VAPID_PUBLIC_KEY = 'BEUL188F_Uj0fESQfe6MVcObVoYwdUunYrmlQH1Ovc8xUmJgNVdSXX33R-35sBw0zP_dLZUhvK4QFi1zrA1ZPCk'
const VAPID_PRIVATE_KEY = Deno.env.get('VAPID_PRIVATE_KEY') || ''
const VAPID_SUBJECT = 'mailto:borstphoto@gmail.com'

// Initialize web-push
webpush.setVapidDetails(VAPID_SUBJECT, VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY)

Deno.serve(async (req) => {
  try {
    // Create Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
    const supabase = createClient(supabaseUrl, supabaseKey, {
      db: { schema: 'chore_chart' }
    })

    // Get current time in HH:MM format
    const now = new Date()
    const currentTime = now.toLocaleTimeString('en-US', {
      hour12: false,
      hour: '2-digit',
      minute: '2-digit',
      timeZone: 'America/Denver' // Adjust to your timezone
    })

    console.log(`Checking reminders for time: ${currentTime}`)

    // Get all active reminders for the current time
    const { data: reminders, error: remindersError } = await supabase
      .from('reminders')
      .select(`
        *,
        users!reminders_child_id_fkey(id, name, push_subscription)
      `)
      .eq('is_active', true)
      .eq('reminder_time', currentTime)

    if (remindersError) {
      console.error('Error fetching reminders:', remindersError)
      return new Response(JSON.stringify({ error: remindersError.message }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    console.log(`Found ${reminders?.length || 0} reminders to send`)

    const results = []

    for (const reminder of reminders || []) {
      const user = reminder.users
      if (!user?.push_subscription) {
        console.log(`No push subscription for user ${user?.name || reminder.child_id}`)
        results.push({ reminder_id: reminder.id, status: 'no_subscription' })
        continue
      }

      try {
        // Build notification payload
        const payload = JSON.stringify({
          title: reminder.reminder_type === 'nightly' ? '😴 Bedtime Reminder' : '⏰ Reminder',
          body: reminder.message || 'Time to check your tasks!',
          url: '/'
        })

        // Send push notification
        await webpush.sendNotification(user.push_subscription, payload)
        console.log(`Sent notification to ${user.name}`)
        results.push({ reminder_id: reminder.id, status: 'sent', user: user.name })
      } catch (pushError: any) {
        console.error(`Error sending to ${user.name}:`, pushError.message)

        // If subscription is expired/invalid, remove it
        if (pushError.statusCode === 410 || pushError.statusCode === 404) {
          await supabase
            .from('users')
            .update({ push_subscription: null })
            .eq('id', user.id)
          console.log(`Removed invalid subscription for ${user.name}`)
        }

        results.push({ reminder_id: reminder.id, status: 'error', error: pushError.message })
      }
    }

    return new Response(JSON.stringify({
      time: currentTime,
      reminders_checked: reminders?.length || 0,
      results
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error: any) {
    console.error('Function error:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }
})
