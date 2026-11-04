import { Global, Module } from '@nestjs/common';
import { PrismaService } from './prisma.service.js';
import { TransactionalPrismaService } from './transactional-prisma.service.js';

@Global()
@Module({
  providers: [PrismaService, TransactionalPrismaService],
  exports: [PrismaService, TransactionalPrismaService],
})
export class PrismaModule {}