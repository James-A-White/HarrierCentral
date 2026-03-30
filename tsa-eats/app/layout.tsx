import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'TSA Eats — Free Meals for TSA Officers',
  description: 'Connecting TSA officers with restaurants during government shutdowns.',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
