import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Harrier Central",
  description: "The social running portal for hashers and kennels",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return children;
}
