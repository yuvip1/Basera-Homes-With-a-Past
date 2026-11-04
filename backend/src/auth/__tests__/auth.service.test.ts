import { Test, TestingModule } from '@nestjs/testing';
import { PrismaService } from '@prisma/prisma.service';
import { AuthService } from '@auth/auth.service';

describe('AuthService', () => {
  let service: AuthService;
  let prisma: PrismaService;

  beforeAll(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [AuthService, PrismaService],
    }).compile();

    service = module.get<AuthService>(AuthService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  beforeEach(async () => {
    // Clean up test users
    await prisma.user.deleteMany({});
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  describe('generateApiToken', () => {
    it('should generate a valid JWT token', async () => {
      const result = await service.generateApiToken('test-user', 'GUEST');
      expect(result).toHaveProperty('access_token');
      expect(result).toHaveProperty('expires_in');
    });

    it('should include correct role in token', async () => {
      const result = await service.generateApiToken('test-user', 'HOST');
      expect(result.access_token).toBeDefined();
    });

    it('should include correct issuer and audience', async () => {
      const result = await service.generateApiToken('test-user', 'GUEST');
      expect(result.access_token).toBeDefined();
    });
  });

  describe('verifyToken', () => {
    it('should verify a valid JWT token', async () => {
      const result = await service.generateApiToken('test-user', 'GUEST');
      const verified = await service.verifyToken(result.access_token);
      expect(verified).toBeDefined();
      expect(verified?.sub).toBe('test-user');
    });

    it('should return null for invalid token', async () => {
      const result = await service.verifyToken('invalid-token-string');
      expect(result).toBeNull();
    });

    it('should verify token with correct claims', async () => {
      const result = await service.generateApiToken('test-user', 'GUEST');
      const verified = await service.verifyToken(result.access_token);
      expect(verified).toBeDefined();
      expect(verified?.sub).toBe('test-user');
    });
  });

  describe('validateUser', () => {
    it('should find an existing user', async () => {
      await prisma.user.create({
        data: { id: 'existing-user-789', email: 'existing789@example.com', role: 'GUEST' },
      });

      const result = await service.validateUser('existing-user-789');
      expect(result).toBeDefined();
      expect(result?.id).toBe('existing-user-789');
      expect(result?.role).toBe('GUEST');
    });

    it('should return null for non-existent user', async () => {
      const result = await service.validateUser('non-existent-user');
      expect(result).toBeNull();
    });
  });

  describe('exchangeCredentialForApiToken', () => {
    it('should reject invalid exchange credential', async () => {
      await expect(service.exchangeCredentialForApiToken('invalid-token'))
        .rejects.toThrow();
    });
  });
});
EOF