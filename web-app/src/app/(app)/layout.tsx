import { ServiceWorkerRegister } from "@/components/shell/ServiceWorkerRegister";

export default function AppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-dvh bg-paper">
      <ServiceWorkerRegister />
      {children}
    </div>
  );
}
