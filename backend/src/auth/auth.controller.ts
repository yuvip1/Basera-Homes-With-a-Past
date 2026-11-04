import { Controller, Post, Get, HttpCode, HttpStatus, UseGuards, Body } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { AuthService } from './auth.service.js';
import { JwtAuthGuard } from './guards/jwt-auth.guard.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { Public } from '../common/decorators/public.decorator.js';

export interface ExchangeRequest {
  exchange_token: string;
}

@ApiTags('Authentication')
@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Public()
  @Post('exchange')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Exchange credential for API access token' })
  @ApiResponse({ status: 200, description: 'Token exchange successful', type: Object })
  @ApiResponse({ status: 401, description: 'Invalid or expired exchange credential' })
  async exchangeToken(@Body() body: ExchangeRequest): Promise<{ access_token: string; expires_in: number; token_type: string }> {
    const result = await this.authService.exchangeCredentialForApiToken(body.exchange_token);
    return { ...result, token_type: 'Bearer' };
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current authenticated user' })
  @ApiResponse({ status: 200, description: 'Current user info' })
  async getMe(@CurrentUser() user: { sub: string; role: string }) {
    return { id: user.sub, role: user.role };
  }

  @Get('health')
  @Public()
  @ApiOperation({ summary: 'Auth service health check' })
  @ApiResponse({ status: 200, description: 'Auth service is healthy' })
  health() {
    return { status: 'ok', service: 'auth' };
  }
}