import type { ReactNode } from "react";
import { ArrowLeft } from "lucide-react";
import { useNavigate } from "react-router-dom";

export function PageHeader({
  title,
  subtitle,
  back = true,
  onBack,
  action,
}: {
  title: string;
  subtitle?: string;
  back?: boolean;
  onBack?: () => void;
  action?: ReactNode;
}) {
  const navigate = useNavigate();
  return (
    <header className="mb-5 flex items-start gap-3">
      {back && (
        <button
          onClick={onBack ?? (() => navigate(-1))}
          aria-label="Back"
          className="mt-0.5 grid h-10 w-10 shrink-0 place-items-center rounded-full border border-border bg-card text-ink-soft transition-colors hover:bg-ink/5"
        >
          <ArrowLeft size={20} />
        </button>
      )}
      <div className="min-w-0 flex-1">
        <h1 className="truncate font-display text-2xl font-extrabold text-ink">
          {title}
        </h1>
        {subtitle && <p className="mt-0.5 text-sm text-ink-muted">{subtitle}</p>}
      </div>
      {action}
    </header>
  );
}
