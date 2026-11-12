-- CreateEnum
CREATE TYPE "StaffRole" AS ENUM ('ADMIN', 'CASHIER');

-- CreateEnum
CREATE TYPE "CustomerStatus" AS ENUM ('ACTIVE', 'BLOCKED');

-- CreateEnum
CREATE TYPE "PointTransactionType" AS ENUM ('PURCHASE', 'WELCOME', 'BIRTHDAY', 'REDEMPTION', 'REDEMPTION_REFUND', 'ADJUSTMENT', 'REVERSAL');

-- CreateEnum
CREATE TYPE "RedemptionStatus" AS ENUM ('PENDING', 'USED', 'CANCELLED', 'EXPIRED');

-- CreateTable
CREATE TABLE "program_settings" (
    "id" INTEGER NOT NULL DEFAULT 1,
    "unit_amount_cop" INTEGER NOT NULL DEFAULT 10000,
    "points_per_unit" INTEGER NOT NULL DEFAULT 10,
    "welcome_bonus_points" INTEGER NOT NULL DEFAULT 20,
    "birthday_bonus_points" INTEGER NOT NULL DEFAULT 100,
    "redemption_ttl_hours" INTEGER NOT NULL DEFAULT 48,
    "points_expiry_months" INTEGER,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "program_settings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "staff_users" (
    "id" UUID NOT NULL,
    "email" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "password_hash" TEXT NOT NULL,
    "role" "StaffRole" NOT NULL DEFAULT 'CASHIER',
    "active" BOOLEAN NOT NULL DEFAULT true,
    "last_login_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "staff_users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "customers" (
    "id" UUID NOT NULL,
    "phone" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "birth_date" DATE,
    "email" TEXT,
    "status" "CustomerStatus" NOT NULL DEFAULT 'ACTIVE',
    "balance" INTEGER NOT NULL DEFAULT 0,
    "qr_token" TEXT NOT NULL,
    "data_consent_at" TIMESTAMPTZ(3) NOT NULL,
    "data_consent_version" TEXT NOT NULL,
    "marketing_consent_at" TIMESTAMPTZ(3),
    "marketing_consent_revoked_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "customers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "otp_codes" (
    "id" UUID NOT NULL,
    "phone" TEXT NOT NULL,
    "code_hash" TEXT NOT NULL,
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "expires_at" TIMESTAMPTZ(3) NOT NULL,
    "consumed_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "otp_codes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "purchases" (
    "id" UUID NOT NULL,
    "customer_id" UUID NOT NULL,
    "invoice_number" TEXT NOT NULL,
    "amount_cop" INTEGER NOT NULL,
    "points_earned" INTEGER NOT NULL,
    "registered_by_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "purchases_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "point_transactions" (
    "id" UUID NOT NULL,
    "customer_id" UUID NOT NULL,
    "type" "PointTransactionType" NOT NULL,
    "points" INTEGER NOT NULL,
    "balance_after" INTEGER NOT NULL,
    "reason" TEXT,
    "purchase_id" UUID,
    "redemption_id" UUID,
    "reversed_transaction_id" UUID,
    "idempotency_key" TEXT,
    "created_by_id" UUID,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "point_transactions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "rewards" (
    "id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "image_url" TEXT,
    "points_cost" INTEGER NOT NULL,
    "stock" INTEGER,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "rewards_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "redemptions" (
    "id" UUID NOT NULL,
    "customer_id" UUID NOT NULL,
    "reward_id" UUID NOT NULL,
    "points_spent" INTEGER NOT NULL,
    "code" TEXT NOT NULL,
    "status" "RedemptionStatus" NOT NULL DEFAULT 'PENDING',
    "expires_at" TIMESTAMPTZ(3) NOT NULL,
    "used_at" TIMESTAMPTZ(3),
    "validated_by_id" UUID,
    "cancelled_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "redemptions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "staff_users_email_key" ON "staff_users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "customers_phone_key" ON "customers"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "customers_qr_token_key" ON "customers"("qr_token");

-- CreateIndex
CREATE INDEX "customers_created_at_idx" ON "customers"("created_at");

-- CreateIndex
CREATE INDEX "otp_codes_phone_created_at_idx" ON "otp_codes"("phone", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "purchases_invoice_number_key" ON "purchases"("invoice_number");

-- CreateIndex
CREATE INDEX "purchases_customer_id_created_at_idx" ON "purchases"("customer_id", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "point_transactions_purchase_id_key" ON "point_transactions"("purchase_id");

-- CreateIndex
CREATE UNIQUE INDEX "point_transactions_reversed_transaction_id_key" ON "point_transactions"("reversed_transaction_id");

-- CreateIndex
CREATE UNIQUE INDEX "point_transactions_idempotency_key_key" ON "point_transactions"("idempotency_key");

-- CreateIndex
CREATE INDEX "point_transactions_customer_id_created_at_idx" ON "point_transactions"("customer_id", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "point_transactions_redemption_id_type_key" ON "point_transactions"("redemption_id", "type");

-- CreateIndex
CREATE INDEX "rewards_active_sort_order_idx" ON "rewards"("active", "sort_order");

-- CreateIndex
CREATE UNIQUE INDEX "redemptions_code_key" ON "redemptions"("code");

-- CreateIndex
CREATE INDEX "redemptions_customer_id_created_at_idx" ON "redemptions"("customer_id", "created_at");

-- CreateIndex
CREATE INDEX "redemptions_status_expires_at_idx" ON "redemptions"("status", "expires_at");

-- AddForeignKey
ALTER TABLE "purchases" ADD CONSTRAINT "purchases_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "purchases" ADD CONSTRAINT "purchases_registered_by_id_fkey" FOREIGN KEY ("registered_by_id") REFERENCES "staff_users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "point_transactions" ADD CONSTRAINT "point_transactions_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "point_transactions" ADD CONSTRAINT "point_transactions_purchase_id_fkey" FOREIGN KEY ("purchase_id") REFERENCES "purchases"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "point_transactions" ADD CONSTRAINT "point_transactions_redemption_id_fkey" FOREIGN KEY ("redemption_id") REFERENCES "redemptions"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "point_transactions" ADD CONSTRAINT "point_transactions_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "staff_users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "point_transactions" ADD CONSTRAINT "point_transactions_reversed_transaction_id_fkey" FOREIGN KEY ("reversed_transaction_id") REFERENCES "point_transactions"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "redemptions" ADD CONSTRAINT "redemptions_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "redemptions" ADD CONSTRAINT "redemptions_reward_id_fkey" FOREIGN KEY ("reward_id") REFERENCES "rewards"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "redemptions" ADD CONSTRAINT "redemptions_validated_by_id_fkey" FOREIGN KEY ("validated_by_id") REFERENCES "staff_users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- =====================================================================
-- Integridad adicional (agregada a mano: Prisma no expresa CHECK ni triggers)
-- =====================================================================

-- Saldos, montos y costos validos
ALTER TABLE "customers" ADD CONSTRAINT "customers_balance_non_negative" CHECK ("balance" >= 0);
ALTER TABLE "purchases" ADD CONSTRAINT "purchases_amount_cop_positive" CHECK ("amount_cop" > 0);
ALTER TABLE "purchases" ADD CONSTRAINT "purchases_points_earned_non_negative" CHECK ("points_earned" >= 0);
ALTER TABLE "point_transactions" ADD CONSTRAINT "point_transactions_points_non_zero" CHECK ("points" <> 0);
ALTER TABLE "point_transactions" ADD CONSTRAINT "point_transactions_balance_after_non_negative" CHECK ("balance_after" >= 0);
ALTER TABLE "rewards" ADD CONSTRAINT "rewards_points_cost_positive" CHECK ("points_cost" > 0);
ALTER TABLE "rewards" ADD CONSTRAINT "rewards_stock_non_negative" CHECK ("stock" IS NULL OR "stock" >= 0);
ALTER TABLE "redemptions" ADD CONSTRAINT "redemptions_points_spent_positive" CHECK ("points_spent" > 0);
ALTER TABLE "otp_codes" ADD CONSTRAINT "otp_codes_attempts_non_negative" CHECK ("attempts" >= 0);

-- Configuracion del programa: una sola fila (id = 1) con valores positivos
ALTER TABLE "program_settings" ADD CONSTRAINT "program_settings_single_row" CHECK ("id" = 1);
ALTER TABLE "program_settings" ADD CONSTRAINT "program_settings_values_valid" CHECK (
  "unit_amount_cop" > 0
  AND "points_per_unit" > 0
  AND "welcome_bonus_points" >= 0
  AND "birthday_bonus_points" >= 0
  AND "redemption_ttl_hours" > 0
  AND ("points_expiry_months" IS NULL OR "points_expiry_months" > 0)
);

-- Libro de movimientos de solo insercion: no se edita ni se borra.
-- Los errores se corrigen con un movimiento REVERSAL o ADJUSTMENT.
CREATE FUNCTION "point_transactions_block_mutation"() RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'point_transactions es de solo insercion: use un movimiento REVERSAL o ADJUSTMENT'
    USING ERRCODE = 'restrict_violation';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "point_transactions_append_only"
  BEFORE UPDATE OR DELETE ON "point_transactions"
  FOR EACH ROW EXECUTE FUNCTION "point_transactions_block_mutation"();

-- Reglas por defecto del programa: 10 puntos por cada $10.000
INSERT INTO "program_settings" ("id", "updated_at") VALUES (1, CURRENT_TIMESTAMP);
