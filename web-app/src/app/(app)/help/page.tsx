"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { ChevronDown, ChevronLeft } from "lucide-react";

import { Button } from "@/components/ui/Button";
import { useT } from "@/components/providers/I18nProvider";
import { config, supportConfigured } from "@/lib/config";
import type { MessageKey } from "@/lib/i18n";
import { toast } from "@/lib/toast";
import { useAppSelector } from "@/store/hooks";

const FAQS: { q: MessageKey; a: MessageKey }[] = [
  { q: "help_faq_1_q", a: "help_faq_1_a" },
  { q: "help_faq_2_q", a: "help_faq_2_a" },
  { q: "help_faq_3_q", a: "help_faq_3_a" },
  { q: "help_faq_4_q", a: "help_faq_4_a" },
  { q: "help_faq_5_q", a: "help_faq_5_a" },
];

export default function HelpPage() {
  const t = useT();
  const router = useRouter();
  const user = useAppSelector((s) => s.auth.user);
  const [open, setOpen] = useState<number | null>(0);
  const [message, setMessage] = useState("");
  const [busy, setBusy] = useState(false);

  async function send() {
    if (!message.trim()) {
      toast.error(t("help_empty_message_error"));
      return;
    }
    if (!supportConfigured) {
      // Fallback: open the user's mail app.
      const subject = encodeURIComponent(t("help_mail_subject"));
      const body = encodeURIComponent(message.trim());
      window.location.href = `mailto:${config.supportEmail}?subject=${subject}&body=${body}`;
      return;
    }
    setBusy(true);
    try {
      const res = await fetch("/api/support", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          message: message.trim(),
          userEmail: user?.email,
          userName: user?.fullName,
        }),
      });
      if (!res.ok) throw new Error();
      toast.success(t("help_message_sent_success"));
      setMessage("");
    } catch {
      toast.error(t("help_send_error"));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="mx-auto min-h-dvh max-w-md bg-paper">
      <header className="flex items-center gap-2 px-4 py-3 safe-top">
        <button onClick={() => router.back()} aria-label="Back" className="text-ink">
          <ChevronLeft size={26} />
        </button>
        <h1 className="text-lg font-bold text-ink">{t("help_title")}</h1>
      </header>

      <div className="px-5 pb-10">
        <h2 className="mb-3 font-bold text-ink">{t("help_faq_title")}</h2>
        <div className="overflow-hidden rounded-xl border border-border">
          {FAQS.map((f, i) => (
            <div key={i} className="border-b border-border last:border-b-0">
              <button
                onClick={() => setOpen(open === i ? null : i)}
                className="flex w-full items-center justify-between gap-2 bg-surface px-4 py-3.5 text-left font-medium text-ink"
              >
                {t(f.q)}
                <ChevronDown
                  size={18}
                  className={`shrink-0 text-ink-muted transition-transform ${open === i ? "rotate-180" : ""}`}
                />
              </button>
              {open === i && (
                <p className="bg-surface px-4 pb-4 text-sm text-ink-muted">{t(f.a)}</p>
              )}
            </div>
          ))}
        </div>

        <h2 className="mb-2 mt-7 font-bold text-ink">{t("help_still_need_help")}</h2>
        <p className="mb-3 text-sm text-ink-muted">{t("help_send_message_body")}</p>
        <textarea
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          placeholder={t("help_message_hint")}
          rows={5}
          className="w-full rounded-md border border-border bg-surface p-3 text-ink outline-none focus:border-accent"
        />
        <Button variant="primary" fullWidth className="mt-3" loading={busy} onClick={send}>
          {t("help_email_support_button")}
        </Button>
      </div>
    </div>
  );
}
