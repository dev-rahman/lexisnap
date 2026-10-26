import { BrandMark } from "@/components/brand/BrandMark";

export default function AuthLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <main className="flex min-h-dvh flex-col bg-paper px-5 py-8 safe-top safe-bottom">
      <div className="mx-auto flex w-full max-w-md flex-1 flex-col">
        <div className="mb-8 mt-6 flex justify-center">
          <BrandMark size="md" />
        </div>
        {children}
      </div>
    </main>
  );
}
