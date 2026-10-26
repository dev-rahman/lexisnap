import type { ReactNode } from "react";

import { Card } from "./Card";
import { IconTile } from "./IconTile";

/** A consistent empty/placeholder block. */
export function EmptyState({
  icon,
  title,
  body,
  action,
}: {
  icon: ReactNode;
  title: string;
  body?: string;
  action?: ReactNode;
}) {
  return (
    <Card className="flex flex-col items-center px-8 py-12 text-center">
      <IconTile size="lg" className="mb-4 bg-accent/12 text-accent">
        {icon}
      </IconTile>
      <p className="text-lg font-bold text-ink">{title}</p>
      {body && <p className="mt-1.5 max-w-xs text-sm text-ink-muted">{body}</p>}
      {action && <div className="mt-5">{action}</div>}
    </Card>
  );
}
