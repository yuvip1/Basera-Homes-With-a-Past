import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from './prisma.service.js';

/**
 * TransactionalPrismaService provides a Prisma client that automatically
 * sets RLS context variables (basera.user_id, basera.user_role) within transactions.
 * This ensures all RLS-protected queries execute within the correct security context.
 */
@Injectable()
export class TransactionalPrismaService {
  constructor(private prisma: PrismaService) {}

  /**
   * Execute a callback within a transaction with RLS context variables set.
   * The callback receives a PrismaClient instance that is bound to the transaction.
   *
   * @param userId - The authenticated user's UUID
   * @param userRole - The user's role (GUEST, HOST, BOTH, ADMIN)
   * @param callback - Function that receives a transactional PrismaClient
   * @returns The result of the callback
   */
  async executeInTransaction<T>(
    userId: string,
    userRole: 'GUEST' | 'HOST' | 'BOTH' | 'ADMIN',
    callback: (tx: Prisma.TransactionClient) => Promise<T>,
  ): Promise<T> {
    return this.prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      // Set RLS context variables for this transaction
      await tx.$executeRaw`SET LOCAL "basera.user_id" = ${userId}`;
      await tx.$executeRaw`SET LOCAL "basera.user_role" = ${userRole}`;

      // Execute the callback with the transactional client
      return callback(tx);
    }, {
      maxWait: 5000,
      timeout: 10000,
    });
  }

  /**
   * Execute a read-only query with RLS context.
   * Uses a read-only transaction for safety.
   */
  async queryInTransaction<T>(
    userId: string,
    userRole: 'GUEST' | 'HOST' | 'BOTH' | 'ADMIN',
    callback: (tx: Prisma.TransactionClient) => Promise<T>,
  ): Promise<T> {
    return this.prisma.$transaction(
      async (tx: Prisma.TransactionClient) => {
        await tx.$executeRaw`SET LOCAL "basera.user_id" = ${userId}`;
        await tx.$executeRaw`SET LOCAL "basera.user_role" = ${userRole}`;
        return callback(tx);
      },
      {
        maxWait: 5000,
        timeout: 10000,
      },
    );
  }

  /**
   * Execute a raw SQL query with RLS context.
   * Useful for raw SQL operations that need RLS context.
   */
  async executeRawInTransaction<T>(
    userId: string,
    userRole: 'GUEST' | 'HOST' | 'BOTH' | 'ADMIN',
    query: string,
    values?: unknown[],
  ): Promise<T> {
    return this.prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      await tx.$executeRaw`SET LOCAL "basera.user_id" = ${userId}`;
      await tx.$executeRaw`SET LOCAL "basera.user_role" = ${userRole}`;
      return tx.$executeRawUnsafe(query, ...(values || [])) as Promise<T>;
    });
  }
}