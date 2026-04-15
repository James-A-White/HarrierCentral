import type { Metadata } from "next";
import { GlobalTabBar } from "@/components/global/GlobalTabBar";

export const metadata: Metadata = {
  title: "hashruns.org — Global Hash Run Discovery",
  description:
    "Find hash runs worldwide. Browse upcoming runs, explore the global calendar, and discover kennels near you.",
};

export default function GlobalLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="dark">
      <body className="text-zinc-100 antialiased overflow-x-hidden">
        {/* Platform background — jungle tile + dark overlay */}
        <div
          className="fixed inset-0 -z-10 bg-repeat"
          style={{
            backgroundImage: "url(/images/jungle_background.jpg)",
            backgroundSize: "1024px 1024px",
          }}
        />
        <div
          className="fixed inset-0 -z-[9]"
          style={{ backgroundColor: "#000000", opacity: 0.55 }}
        />

        <GlobalTabBar />

        {children}
      </body>
    </html>
  );
}
