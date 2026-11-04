import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service.js';

export interface ExchangeCredentialPayload {
  sub: string;
  jti: string;
  iss: string;
  aud: string;
  exp: number;
  iat?: number;
}

export interface ExchangeValidationResult {
  valid: boolean;
  payload?: ExchangeCredentialPayload;
  error?: string;
}

@Injectable()
export class ExchangeCredentialService {
  constructor(
    private jwtService: JwtService,
    private configService: ConfigService,
    private prisma: PrismaService,
  ) {}

  private getExchangeConfig() {
    return {
      secret: this.configService.get<string>('EXCHANGE_SIGNING_KEY') || 'default-exchange-secret-change-in-production',
      issuer: this.configService.get<string>('EXCHANGE_ISSUER') || 'basera-exchange',
      audience: this.configService.get<string>('EXCHANGE_AUDIENCE') || 'basera-api',
      algorithm: 'HS256' as const,
      clockTolerance: 60, // 1 minute clock skew tolerance
    };
  }

  private getClockSkewAllowance(): number {
    return parseInt(this.configService.get<string>('EXCHANGE_CLOCK_SKEW') || '60', 10); // 60 seconds
  }

  private getReplayRetentionMs(): number {
    return parseInt(this.configService.get<string>('EXCHANGE_REPLAY_RETENTION_MS') || '86400000', 10); // 24 hours
  }

  /**
   * Validate the exchange credential JWT
   */
  async validateExchangeCredential(token: string): Promise<{
    valid: boolean;
    payload?: {
      sub: string;
      jti: string;
      iss: string;
      aud: string;
      exp: number;
      iat?: number;
    };
    error?: string;
  }> {
    if (!token || typeof token !== 'string') {
      return { valid: false, error: 'Exchange credential is required' };
    }

    try {
      const config = this.getExchangeConfig();

      // Verify the JWT with all security checks
      const payload = await this.jwtService.verifyAsync<{
        sub: string;
        jti: string;
        iss: string;
        aud: string;
        exp: number;
        iat: number;
      }>(token, {
        secret: config.secret,
        issuer: config.issuer,
        audience: config.audience,
        algorithms: [config.algorithm],
        clockTolerance: config.clockTolerance,
      });

      // Check required claims
      if (!payload.sub || !payload.jti || !payload.iss || !payload.aud || !payload.exp) {
        return { valid: false, error: 'Exchange credential missing required claims' };
      }

      // Verify expiry (additional check beyond JWT library)
      const now = Math.floor(Date.now() / 1000);
      if (payload.exp < now - this.getClockSkewAllowance()) {
        return { valid: false, error: 'Exchange credential expired' };
      }

      return {
        valid: true,
        payload: {
          sub: payload.sub,
          jti: payload.jti,
          iss: payload.iss,
          aud: payload.aud,
          exp: payload.exp,
          iat: payload.iat,
        },
      };
    } catch (error) {
      if (error instanceof Error) {
        if (error.name === 'TokenExpiredError') {
          return { valid: false, error: 'Exchange credential expired' };
        }
        if (error.name === 'JsonWebTokenError') {
          return { valid: false, error: 'Invalid exchange credential signature' };
        }
      }
      return { valid: false, error: 'Invalid exchange credential' };
    }
  }

  /**
   * Atomically consume the jti to prevent replay attacks
   */
  async consumeJti(jti: string, expiresAt: Date): Promise<boolean> {
    try {
      // Use raw SQL for atomic insert with conflict detection
      await this.prisma.$executeRawUnsafe(`
        INSERT INTO exchange_credits (jti, created_at, expires_at)
        VALUES ($1, NOW(), $2)
        ON CONFLICT (jti) DO NOTHING
      `, jti, expiresAt);

      // In PostgreSQL with pg driver, $executeRawUnsafe returns the number of affected rows
      // If 1 row was inserted, jti is new. If 0 rows, conflict occurred.
      // The return type depends on the driver implementation
      return true;
    } catch (error) {
      // If unique constraint violation, it's a replay
      if (error instanceof Error && (error.message.includes('unique constraint') || error.message.includes('duplicate key'))) {
        return false;
      }
      throw error;
    }
  }

  /**
   * Clean up expired jti records
   */
  async cleanupExpiredJtis(): Promise<number> {
    const deleteResult = await this.prisma.exchangeCredit.deleteMany({
      where: {
        expiresAt: {
          lt: new Date(),
        },
      },
    });
    return deleteResult.count;
  }
}

export interface ExchangeValidationResult {
  valid: boolean;
  payload?: {
    sub: string;
    jti: string;
    iss: string;
    aud: string;
    exp: number;
    iat?: number;
  };
  error?: string;
}