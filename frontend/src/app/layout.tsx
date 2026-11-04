import type { Metadata } from 'next';
import { AuthProvider } from '@/app/providers';
import './globals.css';

export const metadata: Metadata = {
  title: 'Basera — Heritage Homestay Booking',
  description: 'Book heritage homes with a past',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <AuthProvider>{children}</AuthProvider>
      </body>
    </html>
  );
}