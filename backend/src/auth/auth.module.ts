import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtStrategy } from './jwt.strategy.js';
import { AuthController } from './auth.controller.js';
import { AuthService } from './auth.service.js';
import { ExchangeCredentialService } from './exchange-credential.service.js';
import { JwtAuthGuard } from './guards/jwt-auth.guard.js';
import { RolesGuard } from './guards/roles.guard.js';

@Module({
  imports: [
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => ({
        secretOrPrivateKey: configService.get<string>('JWT_PRIVATE_KEY') || configService.get<string>('JWT_SECRET'),
        publicKey: configService.get<string>('JWT_PUBLIC_KEY'),
        signOptions: {
          algorithm: (configService.get<string>('JWT_ALGORITHM') || 'RS256') as 'RS256' | 'HS256',
          issuer: configService.get<string>('JWT_ISSUER') || 'basera-backend',
          audience: configService.get<string>('JWT_AUDIENCE') || 'basera-api',
          expiresIn: configService.get<string>('JWT_EXPIRES_IN') || '5m',
        },
        verifyOptions: {
          algorithms: ['RS256', 'HS256'],
          issuer: configService.get<string>('JWT_ISSUER') || 'basera-backend',
          audience: configService.get<string>('JWT_AUDIENCE') || 'basera-api',
        },
      }),
      inject: [ConfigService],
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, ExchangeCredentialService, JwtStrategy, JwtAuthGuard, RolesGuard],
  exports: [AuthService, ExchangeCredentialService, JwtModule, JwtAuthGuard, RolesGuard],
})
export class AuthModule {}