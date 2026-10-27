// Help/contact form delivery. Uses the EmailJS browser SDK (public key only —
// safe to ship) when configured; otherwise callers fall back to a mailto: link.

import emailjs from "@emailjs/browser";

import { config, supportConfigured } from "@/lib/config";

export function supportAvailable(): boolean {
  return supportConfigured;
}

export async function sendSupportMessage(args: {
  message: string;
  fromEmail: string | null;
}): Promise<void> {
  await emailjs.send(
    config.emailjs.serviceId,
    config.emailjs.templateSupport,
    {
      message: args.message,
      from_email: args.fromEmail ?? "anonymous",
      reply_to: args.fromEmail ?? config.supportEmail,
    },
    { publicKey: config.emailjs.publicKey },
  );
}

/** A mailto: fallback for when EmailJS isn't configured. */
export function supportMailto(subject: string, message: string): string {
  const params = new URLSearchParams({ subject, body: message });
  return `mailto:${config.supportEmail}?${params.toString()}`;
}
