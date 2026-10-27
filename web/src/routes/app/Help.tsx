import { useState } from "react";
import { ChevronDown, Send } from "lucide-react";

import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { PageHeader } from "@/components/shell/PageHeader";
import {
  sendSupportMessage,
  supportAvailable,
  supportMailto,
} from "@/lib/services/support";
import { toast } from "@/lib/toast";
import { useT } from "@/providers/I18nProvider";
import { useAppSelector } from "@/store/hooks";
import { cn } from "@/lib/utils/cn";

export function Help() {
  const t = useT();
  const email = useAppSelector((s) => s.auth.user?.email) ?? null;
  const [open, setOpen] = useState<number | null>(0);
  const [message, setMessage] = useState("");
  const [sending, setSending] = useState(false);

  const faqs = [1, 2, 3, 4, 5].map((n) => ({
    q: t(`help_faq_${n}_q` as "help_faq_1_q"),
    a: t(`help_faq_${n}_a` as "help_faq_1_a"),
  }));

  async function onSend() {
    if (!message.trim()) return toast.warning(t("help_empty_message_error"));
    if (!supportAvailable()) {
      window.location.href = supportMailto(t("help_mail_subject"), message);
      return;
    }
    setSending(true);
    try {
      await sendSupportMessage({ message: message.trim(), fromEmail: email });
      setMessage("");
      toast.success(t("help_message_sent_success"));
    } catch {
      window.location.href = supportMailto(t("help_mail_subject"), message);
    } finally {
      setSending(false);
    }
  }

  return (
    <div className="mx-auto max-w-2xl">
      <PageHeader title={t("help_title")} />

      <section className="space-y-5">
        <div>
          <h2 className="mb-3 font-display text-lg font-extrabold text-ink">
            {t("help_faq_title")}
          </h2>
          <Card padded={false} className="divide-y divide-border overflow-hidden">
            {faqs.map((faq, i) => (
              <div key={i}>
                <button
                  onClick={() => setOpen(open === i ? null : i)}
                  className="flex w-full items-center justify-between gap-3 px-4 py-4 text-left hover:bg-ink/[0.03]"
                >
                  <span className="font-semibold text-ink">{faq.q}</span>
                  <ChevronDown
                    size={20}
                    className={cn(
                      "shrink-0 text-ink-muted transition-transform",
                      open === i && "rotate-180",
                    )}
                  />
                </button>
                {open === i && (
                  <p className="animate-[rise-in_0.2s_ease-out] px-4 pb-4 text-[15px] text-ink-muted">
                    {faq.a}
                  </p>
                )}
              </div>
            ))}
          </Card>
        </div>

        <Card className="space-y-3">
          <h2 className="font-display text-lg font-extrabold text-ink">
            {t("help_still_need_help")}
          </h2>
          <p className="text-sm text-ink-muted">{t("help_send_message_body")}</p>
          <textarea
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            placeholder={t("help_message_hint")}
            rows={5}
            className="w-full resize-none rounded-2xl border-2 border-border bg-card px-4 py-3 text-[15px] text-ink placeholder:text-ink-muted/70 focus:border-coral focus:outline-none focus:ring-4 focus:ring-coral/15"
          />
          <Button onClick={onSend} loading={sending} leftIcon={<Send size={18} />}>
            {t("help_email_support_button")}
          </Button>
        </Card>
      </section>
    </div>
  );
}
