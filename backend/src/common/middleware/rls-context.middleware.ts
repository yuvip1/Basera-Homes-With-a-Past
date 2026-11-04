import { Injectable, NestMiddleware, UnauthorizedException } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { JwtService } from '@nestjs/jwt';

@Injectable()
export class RlsContextMiddleware implements NestMiddleware {
  constructor(private jwtService: JwtService) {}

  async use(req: Request, res: Response, next: NextFunction): Promise<void> {
    // Skip for public endpoints
    if (this.isPublicPath(req.path)) {
      return next();
    }

    // Extract JWT from Authorization header
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Missing or invalid Authorization header');
    }

    const token = authHeader.substring(7); // Remove 'Bearer ' prefix

    // Verify JWT and extract payload
    try {
      const payload = await this.jwtService.verifyAsync(token, {
        issuer: 'basera-backend',
        audience: 'basera-api',
      });

      // Attach user info to request for use in transaction middleware
      (req as any).userId = payload.sub;
      (req as any).userRole = payload.role;
      (req as any).user = {
        sub: payload.sub,
        role: payload.role,
      };

      next();
    } catch (error) {
      if (error instanceof Error && error.name === 'TokenExpiredError') {
        throw new UnauthorizedException('Token expired');
      }
      if (error instanceof Error && error.name === 'JsonWebTokenError') {
        throw new UnauthorizedException('Invalid token');
      }
      throw new UnauthorizedException('Invalid or expired token');
    }
  }

  private isPublicPath(path: string): boolean {
    const publicPaths = [
      '/auth/health',
      '/auth/exchange',
    ];
    return publicPaths.some((p) => path.startsWith(p));
  }
}