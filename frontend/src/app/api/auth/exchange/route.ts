import { auth } from '@/lib/auth';
import { NextResponse } from 'next/server';

export async function POST(request: Request) {
  try {
    // Get the session using NextAuth's server-side session retrieval
    // In NextAuth v5 with App Router, we use auth() with the request object
    // The auth() function accepts a Request object in the App Router
    // Using @ts-expect-error to bypass TypeScript issue with Request type
    // @ts-expect-error - NextAuth v5 supports Request object in App Router but TypeScript doesn't recognize the overload
    const session = await auth(request);

    if (!session?.user?.id) {
      return NextResponse.json(
        { error: 'Invalid or expired session' },
        { status: 401 }
      );
    }

    // Create a short-lived exchange credential
    const exchangeToken = await createExchangeCredential(session.user.id);

    // Send the exchange credential to the backend
    const backendUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';

    // Validate origin for CSRF protection
    const origin = request.headers.get('origin');
    const expectedOrigin = process.env.NEXTAUTH_URL || 'http://localhost:3000';
    if (origin && origin !== expectedOrigin) {
      return NextResponse.json(
        { error: 'Invalid origin' },
        { status: 403 }
      );
    }

    const response = await fetch(`${backendUrl}/api/auth/exchange`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ exchange_token: exchangeToken }),
    });

    if (!response.ok) {
      const error = await response.json();
      return NextResponse.json(
        { error: error.message || 'Exchange failed' },
        { status: response.status }
      );
    }

    const data = await response.json();

    // Return the API token to the frontend
    return NextResponse.json({
      access_token: data.access_token,
      expires_in: data.expires_in,
      token_type: data.token_type,
    });
  } catch (error) {
    console.error('Exchange error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

async function createExchangeCredential(userId: string): Promise<string> {
  const { SignJWT } = await import('jose');
  const secret = new TextEncoder().encode(
    process.env.EXCHANGE_SIGNING_KEY || 'default-exchange-secret-change-in-production'
  );

  const now = Math.floor(Date.now() / 1000);
  const exp = now + 60; // 60 seconds expiry for exchange credential

  const token = await new SignJWT({
    sub: userId,
    jti: crypto.randomUUID(),
    iss: 'basera-exchange',
    aud: 'basera-api',
  })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime(exp)
    .sign(secret);

  return token;
}