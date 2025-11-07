/*
  Warnings:

  - Added the required column `cantidad` to the `transacciones` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "transacciones" ADD COLUMN     "cantidad" INTEGER NOT NULL,
ADD COLUMN     "confirmacion_comprador" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "confirmacion_vendedor" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "precio_total" DECIMAL(10,2),
ADD COLUMN     "precio_unitario" DECIMAL(10,2);
