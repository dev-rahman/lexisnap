import { NextResponse, type NextRequest } from "next/server";

// Sends support mail via EmailJS — server-side so the EmailJS PRIVATE key
// (access token) never ships to the browser. Ports emailjs_support_service.dart.
const ENDPOINT = "https://api.emailjs.com/api/v1.0/email/send";

const SERVICE_ID = process.env.NEXT_PUBLIC_EMAILJS_SERVICE_ID ?? "";
const PUBLIC_KEY = process.env.NEXT_PUBLIC_EMAILJS_PUBLIC_KEY ?? "";
const TEMPLATE_SUPPORT = process.env.NEXT_PUBLIC_EMAILJS_TEMPLATE_SUPPORT ?? "";
const TEMPLATE_RECEIPT = process.env.NEXT_PUBLIC_EMAILJS_TEMPLATE_RECEIPT ?? "";
const PRIVATE_KEY = process.env.EMAILJS_PRIVATE_KEY ?? "";
const SUPPORT_EMAIL = process.env.NEXT_PUBLIC_SUPPORT_EMAIL ?? "support@lexisnap.app";

async function send(templateId: string, params: Record<string, string>) {
  const res = await fetch(ENDPOINT, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      service_id: SERVICE_ID,
      template_id: templateId,
      user_id: PUBLIC_KEY,
      template_params: params,
      ...(PRIVATE_KEY ? { accessToken: PRIVATE_KEY } : {}),
    }),
  });
  if (!res.ok) {
    throw new Error(`EmailJS ${res.status}: ${await res.text()}`);
  }
}

export async function POST(request: NextRequest) {
  if (!SERVICE_ID || !PUBLIC_KEY || !TEMPLATE_SUPPORT || !TEMPLATE_RECEIPT) {
    return NextResponse.json({ error: "Support not configured" }, { status: 503 });
  }

  const { message, userEmail, userName } = await request.json();
  if (!message || !userEmail) {
    return NextResponse.json({ error: "Missing fields" }, { status: 400 });
  }

  const shared = {
    user_name: (userName as string)?.trim() || "A LexiSnap user",
    user_email: userEmail as string,
    message: (message as string).trim(),
    platform: "Web",
    submitted_at: new Date().toISOString(),
  };

  try {
    await send(TEMPLATE_SUPPORT, { ...shared, to_email: SUPPORT_EMAIL, reply_to: userEmail });
  } catch (e) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "send failed" },
      { status: 502 },
    );
  }

  // User's copy is best-effort.
  try {
    await send(TEMPLATE_RECEIPT, { ...shared, to_email: userEmail, reply_to: SUPPORT_EMAIL });
  } catch {
    // ignore
  }

  return NextResponse.json({ ok: true });
}
