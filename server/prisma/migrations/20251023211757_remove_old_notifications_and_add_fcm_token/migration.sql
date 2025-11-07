/*
  Warnings:

  - You are about to drop the `notificaciones` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "public"."notificaciones" DROP CONSTRAINT "notificaciones_usuario_id_fkey";

-- AlterTable
ALTER TABLE "cuentas" ADD COLUMN     "fcm_token" TEXT;

-- AlterTable
ALTER TABLE "productos" ADD COLUMN     "visible" BOOLEAN NOT NULL DEFAULT true;

-- DropTable
DROP TABLE "public"."notificaciones";
