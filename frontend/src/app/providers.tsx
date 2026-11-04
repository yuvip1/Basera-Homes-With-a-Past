'use client';

import { SessionProvider } from 'next-auth/react';
import { ReactNode } from 'react';
import { useEffect } from 'react';

export function AuthProvider({ children }: { children: ReactNode }) {
  // Exchange session for API token on mount
  useEffect(() => {
    const exchangeSession = async () => {
      try {
        const res = await fetch('/api/auth/exchange', {
          method: 'POST',
          credentials: 'include', // Send session cookie
        });

        if (!res.ok) {
          throw new Error('Session exchange failed');
        }

        await res.json();
      } catch (error) {
        console.error('Token exchange error:', error);
      }
    };

    exchangeSession();
  }, []);

  return (
    <SessionProvider>{children}</SessionProvider>
  );
}