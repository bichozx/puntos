# Puntos

Programa de fidelización y puntos para restaurante. Monorepo con pnpm:

- `apps/api`: API en NestJS 12 + Prisma 7 + PostgreSQL 18
- `apps/web`: PWA del cliente y panel administrativo en Next.js 16

## Requisitos

- Node.js 26 LTS
- pnpm 12
- Docker Desktop

## Inicio local

```bash
# 1. Variables de entorno
cp .env.example .env
cp apps/api/.env.example apps/api/.env
cp apps/web/.env.example apps/web/.env.local
# (ajusta las claves en cada archivo)

# 2. Dependencias y base de datos
pnpm install
docker compose up -d postgres

# 3. Migraciones y cliente de Prisma
cd apps/api
pnpm exec prisma migrate dev
cd ../..

# 4. Levantar la API
pnpm dev:api
```

PostgreSQL queda expuesto en `localhost:5433` (configurable con `POSTGRES_PORT`).

## Comandos útiles

```bash
pnpm build:api      # compilar la API
pnpm test:api       # pruebas
pnpm lint:api       # linter
cd apps/api && pnpm exec prisma studio   # explorar la base de datos
```

## Base de datos

El libro de movimientos (`point_transactions`) es de solo inserción: un trigger
bloquea UPDATE y DELETE. Los errores se corrigen con un movimiento `REVERSAL` o
`ADJUSTMENT`. El saldo en `customers.balance` es una caché que se actualiza en la
misma transacción que el movimiento.
