// Supabase Edge Function: generate-example
//
// Generates ONE natural example sentence for a single word, in that word's
// language, for the flashcard detail view ("Generate example sentence"). Backed
// by Groq (gpt-oss-120b); the Groq API key lives here as a Supabase secret and
// is never shipped inside the app.
//
// Auth: `verify_jwt` (Supabase's default) only proves the bearer token is a
// valid project JWT - and the public anon key is one - so it does NOT by itself
// keep anonymous traffic off this paid Groq call. The handler additionally
// requires a real signed-in user and charges a per-user daily cap, exactly like
// extract-vocabulary / translate-words.
//
// Deploy: supabase functions deploy generate-example
// Secret:  supabase secrets set GROQ_API_KEY=gsk_... (shared with the others)

import {
  createClient,
  type SupabaseClient,
} from "npm:@supabase/supabase-js@2";

const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY");
// Auto-injected into every Edge Function by Supabase.
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");
const MAX_WORD_LEN = 80;

// Daily per-user cap on this (Groq-backed) "example" action, by subscription
// tier. Until billing exists every user resolves to 'free'; when it does,
// derive the tier in `tierFor` and these numbers apply automatically. One
// sentence per call, so the caps sit between scans and translates.
const EXAMPLE_LIMITS = { free: 10, plus: 100, pro: 400 } as const;
type Tier = keyof typeof EXAMPLE_LIMITS;
function tierFor(_user: { id: string }): Tier {
  return "free";
}

// A Supabase client scoped to the caller's bearer token, so Postgres sees them
// as the authenticated user (auth.uid() resolves, RLS applies) - needed for the
// quota RPCs. Returns the client and token, or null when auth is missing.
function authContext(
  req: Request,
): { client: SupabaseClient; token: string } | null {
  const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!token || !SUPABASE_URL || !SUPABASE_ANON_KEY) return null;
  const client = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
  return { client, token };
}

function buildSystemPrompt(language: string | undefined, level: string | undefined): string {
  const langHint = language
    ? `Write the sentence in ${language}. `
    : "Write the sentence in the same language as the word. ";
  const levelHint = level
    ? `Match roughly a ${level} (CEFR) learner's level. `
    : "";
  return (
    "You are a helper for a language-learning flashcard app. Write ONE short, " +
    "natural example sentence that uses the given word in a clear, everyday " +
    `context. ${langHint}${levelHint}The sentence must actually contain the ` +
    "word. Respond with ONLY a JSON object of this exact shape, no other " +
    'text: {"sentence": string}.'
  );
}

// Allow the browser web app to call this function cross-origin. The old Flutter
// client used native HTTP (no CORS enforcement); the web client needs these
// headers on every response, plus an OPTIONS preflight answer below.
const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  if (!GROQ_API_KEY) {
    return jsonResponse({ error: "Server misconfigured" }, 500);
  }

  // Gate the Groq call behind a real signed-in user (see note above):
  // verify_jwt alone is satisfied by the public anon key.
  const ctx = authContext(req);
  if (!ctx) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }
  const { data: userData, error: userError } = await ctx.client.auth.getUser(
    ctx.token,
  );
  const user = userData?.user;
  if (userError || !user || user.role !== "authenticated") {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  let word: unknown;
  let language: unknown;
  let level: unknown;
  try {
    const body = await req.json();
    word = body?.word;
    language = body?.language;
    level = body?.level;
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  if (typeof word !== "string" || word.trim().length === 0) {
    return jsonResponse({ error: "\"word\" is required" }, 400);
  }
  if (language !== undefined && typeof language !== "string") {
    return jsonResponse({ error: "\"language\" must be a string" }, 400);
  }
  if (level !== undefined && level !== null && typeof level !== "string") {
    return jsonResponse({ error: "\"level\" must be a string" }, 400);
  }
  const trimmedWord = word.trim().slice(0, MAX_WORD_LEN);

  // Charge one example against the user's daily cap for their tier, before the
  // (expensive) Groq call. -1 means they're already at the cap today.
  const exampleLimit = EXAMPLE_LIMITS[tierFor(user)];
  const { data: remaining, error: quotaError } = await ctx.client.rpc(
    "consume_ai_quota",
    { p_action: "example", p_limit: exampleLimit },
  );
  if (quotaError) {
    console.error("consume_ai_quota failed", quotaError);
    return jsonResponse({ error: "Internal error" }, 500);
  }
  if (remaining === -1) {
    return jsonResponse(
      {
        error: "Daily example limit reached",
        code: "quota_exceeded",
        limit: exampleLimit,
      },
      429,
    );
  }

  // Give the quota back on any non-success, so a Groq outage or a malformed
  // response doesn't burn the user's daily allowance.
  let exampleSucceeded = false;
  try {
    const groqResponse = await fetch(
      "https://api.groq.com/openai/v1/chat/completions",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${GROQ_API_KEY}`,
        },
        body: JSON.stringify({
          model: "openai/gpt-oss-120b",
          messages: [
            {
              role: "system",
              content: buildSystemPrompt(
                language as string | undefined,
                (level ?? undefined) as string | undefined,
              ),
            },
            { role: "user", content: trimmedWord },
          ],
          response_format: { type: "json_object" },
        }),
      },
    );

    if (!groqResponse.ok) {
      const errorBody = await groqResponse.text();
      console.error("Groq error", groqResponse.status, errorBody);
      return jsonResponse({ error: "Upstream AI request failed" }, 502);
    }

    const completion = await groqResponse.json();
    const content = completion.choices?.[0]?.message?.content;
    if (typeof content !== "string") {
      return jsonResponse({ error: "Malformed AI response" }, 502);
    }

    let parsed: unknown;
    try {
      parsed = JSON.parse(content);
    } catch {
      return jsonResponse({ error: "AI response was not valid JSON" }, 502);
    }

    const sentence = (parsed as { sentence?: unknown })?.sentence;
    if (typeof sentence !== "string" || sentence.trim().length === 0) {
      return jsonResponse({ error: "No valid sentence in AI response" }, 502);
    }

    exampleSucceeded = true;
    return jsonResponse({ sentence: sentence.trim() }, 200);
  } catch (error) {
    console.error("generate-example failed", error);
    return jsonResponse({ error: "Internal error" }, 500);
  } finally {
    if (!exampleSucceeded) {
      await ctx.client.rpc("refund_ai_quota", { p_action: "example" });
    }
  }
});

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
  });
}
