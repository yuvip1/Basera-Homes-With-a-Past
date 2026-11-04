import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service.js';

export interface JwtPayload {
  sub: string;
  role: 'GUEST' | 'HOST' | 'BOTH' | 'ADMIN';
  iat: number;
  exp: number;
  iss: string;
  aud: string;
  jti?: string;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(
    private configService: ConfigService,
    private prisma: PrismaService,
  ) {
    const secret = configService.get<string>('JWT_SECRET');
    const publicKey = configService.get<string>('JWT_PUBLIC_KEY');

    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: publicKey || secret,
      algorithms: ['RS256', 'HS256'],
      issuer: configService.get<string>('JWT_ISSUER') || 'basera-backend',
      audience: configService.get<string>('JWT_AUDIENCE') || 'basera-api',
      passReqToCallback: false,
    });
  }

  async validate(payload: JwtPayload): Promise<JwtPayload> {
    // Verify user still exists and is active
    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      select: { id: true, role: true, authProvider: true, authSubject: true },
    });

    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    // Check if user role matches token (detect role changes)
    if (user.role !== payload.role) {
      throw new UnauthorizedException('User role has changed, please re-authenticate');
    }

    // Check if user has been disabled (could add isActive field later)
    // For now, we just verify existence and role match

    return payload;
  }
}