// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts"

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'

console.log("Hello from Functions!")

interface EmailPayload {
  to: string
  subject: string
  name: string
  password: string
}

serve(async (req) => {
  try {
    const { to, subject, name, password } = await req.json()

    // Create a Supabase client with the Auth admin key
    const supabaseClient = createClient(
      Deno.env.get('PROJECT_URL') ?? '',
      Deno.env.get('SERVICE_ROLE_KEY') ?? ''
    )

    // Create the user in Supabase Auth
    const { data: authData, error: authError } = await supabaseClient.auth.admin.createUser({
      email: to,
      password: password,
      email_confirm: true
    })

    if (authError) {
      console.error('Auth error:', authError)
      throw authError
    }

    // Send welcome email
    const { error: emailError } = await supabaseClient.auth.admin.sendRawEmail({
      to,
      subject,
      text: `Hello ${name},\n\nWelcome to the Library Management System! Your account has been created successfully.\n\nHere are your login credentials:\nEmail: ${to}\nPassword: ${password}\n\nPlease log in and change your password immediately for security purposes.\n\nBest regards,\nLibrary Management Team`
    })

    if (emailError) {
      console.error('Email error:', emailError)
      throw emailError
    }

    return new Response(
      JSON.stringify({ message: 'Librarian account created and welcome email sent successfully' }),
      {
        headers: { 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    console.error('Function error:', error)
    return new Response(
      JSON.stringify({ 
        error: error.message,
        details: error.details || 'No additional details available'
      }),
      {
        headers: { 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/send-librarian-welcome-email' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
