import { BrandMark } from "@/components/brand/BrandMark";

export default function AuthLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <main className="flex min-h-dvh flex-col items-center justify-center bg-paper px-5 py-10 safe-top safe-bottom">
      <div className="w-full max-w-md">
        <div className="mb-7 flex justify-center">
          <BrandMark size="md" />
        </div>
        <div className="card rounded-2xl p-6 sm:p-8">{children}</div>
      </div>
    </main>
  );
}
