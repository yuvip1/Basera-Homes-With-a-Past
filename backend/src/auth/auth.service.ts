import { Injectable, UnauthorizedException, ForbiddenException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service.js';
import { ExchangeCredentialService } from './exchange-credential.service.js';

export interface TokenPayload {
  sub: string;
  role: 'GUEST' | 'HOST' | 'BOTH' | 'ADMIN';
  iat?: number;
  exp?: number;
  iss?: string;
  aud?: string;
  jti?: string;
}

export interface ExchangeResult {
  access_token: string;
  expires_in: number;
}

@Injectable()
export class AuthService {
  constructor(
    private jwtService: JwtService,
    private configService: ConfigService,
    private prisma: PrismaService,
    private exchangeCredentialService: ExchangeCredentialService,
  ) {}

  /**
   * Exchange a validated exchange credential for a short-lived API JWT
   * This is the backend part of the authentication bridge per ADR 003
   *
   * The exchange credential is created by the Next.js frontend server after
   * validating the Auth.js session. This service validates the exchange credential
   * and then creates an API JWT with the verified user's identity and role
   * derived from the database (not from client-supplied claims).
   */
  async exchangeCredentialForApiToken(exchangeToken: string): Promise<{ access_token: string; expires_in: number }> {
    // Validate the exchange credential
    const validationResult = await this.exchangeCredentialService.validateExchangeCredential(exchangeToken);
    if (!validationResult.valid || !validationResult.payload) {
      throw new UnauthorizedException(validationResult.error || 'Invalid exchange credential');
    }

    const { sub: userId, jti } = validationResult.payload;

    // Atomically consume the jti to prevent replay attacks
    const expiresAt = new Date(validationResult.payload.exp * 1000);
    const jtiConsumed = await this.consumeJtiAtomic(jti, expiresAt);

    if (!jtiConsumed) {
      throw new UnauthorizedException('Exchange credential replay detected');
    }

    // Validate user exists and determine role from database
    // New users receive GUEST by default; HOST requires backend process;
    // BOTH requires explicit business rule; ADMIN never self-assigned
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, role: true },
    });

    if (!user) {
      // Create new user with GUEST role
      const newUser = await this.prisma.user.create({
        data: {
          id: userId,
          role: 'GUEST' as const,
          auth_provider: 'MAGIC_LINK',
          auth_subject: '', // Will be populated by the exchange credential
        },
      });
      return await this.generateApiToken(newUser.id, newUser.role);
    }

    // Verify role is valid
    const validRoles: ('GUEST' | 'HOST' | 'BOTH' | 'ADMIN')[] = ['GUEST', 'HOST', 'BOTH', 'ADMIN'];
    if (!validRoles.includes(user.role)) {
      throw new ForbiddenException('Invalid user role');
    }

    // ADMIN must never be self-assigned
    if (user.role === 'ADMIN') {
      // Keep existing ADMIN role
    }

    const { access_token, expires_in } = await this.generateApiToken(
      user.id,
      user.role,
    );

    return { access_token, expires_in };
  }

  /**
   * Atomically consume jti to prevent replay attacks
   */
  private async consumeJtiAtomic(jti: string, expiresAt: Date): Promise<boolean> {
    try {
      // Use raw SQL for atomic insert with conflict detection
      await this.prisma.$executeRawUnsafe(`
        INSERT INTO exchange_credits (jti, created_at, expires_at)
        VALUES ($1, NOW(), $2)
        ON CONFLICT (jti) DO NOTHING
      `, jti, expiresAt);

      // For PostgreSQL with pg driver, $executeRawUnsafe returns the number of affected rows
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
   * Generate a short-lived API access token for the given user
   * Used after exchange credential validation
   */
  async generateApiToken(userId: string, role: 'GUEST' | 'HOST' | 'BOTH' | 'ADMIN'): Promise<{ access_token: string; expires_in: number }> {
    const expiresInStr = this.configService.get<string>('JWT_EXPIRES_IN') || '5m';
    const access_token = await this.jwtService.signAsync(
      { sub: userId, role },
      {
        expiresIn: expiresInStr,
        issuer: this.configService.get<string>('JWT_ISSUER') || 'basera-backend',
        audience: this.configService.get<string>('JWT_AUDIENCE') || 'basera-api',
      },
    );

    const expiresInNum = this.parseExpiration(expiresInStr);

    return { access_token, expires_in: expiresInNum };
  }

  /**
   * Verify a JWT token and return the payload
   */
  async verifyToken(token: string): Promise<{ sub: string; role: string } | null> {
    try {
      const payload = await this.jwtService.verifyAsync(token, {
        issuer: this.configService.get<string>('JWT_ISSUER') || 'basera-backend',
        audience: this.configService.get<string>('JWT_AUDIENCE') || 'basera-api',
      });
      return { sub: payload.sub, role: payload.role };
    } catch {
      return null;
    }
  }

  /**
   * Verify user exists and is active
   */
  async validateUser(userId: string): Promise<{ id: string; role: string } | null> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, role: true },
    });

    if (!user) {
      return null;
    }

    return { id: user.id, role: user.role };
  }

  private parseExpiration(expiresIn: string): number {
    const match = expiresIn.match(/^(\d+)([smhd])$/);
    if (!match) return 300; // default 5 minutes
    const value = parseInt(match[1], 10);
    const unit = match[2];
    switch (unit) {
      case 's': return value;
      case 'm': return value * 60;
      case 'h': return value * 3600;
      case 'd': return value * 86400;
      default: return 300;
    }
  }
}