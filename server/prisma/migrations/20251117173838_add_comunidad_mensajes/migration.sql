/*
  Warnings:

  - You are about to drop the column `apellido` on the `cuentas` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "cuentas" DROP COLUMN "apellido",
ADD COLUMN     "foto_perfil_url" VARCHAR(500);

-- AlterTable
ALTER TABLE "imagenes_producto" ADD COLUMN     "imagen_data" BYTEA,
ADD COLUMN     "mime_type" VARCHAR(50),
ALTER COLUMN "url_imagen" SET DATA TYPE TEXT;

-- AlterTable
ALTER TABLE "productos" ADD COLUMN     "estado_producto" VARCHAR(20),
ADD COLUMN     "informacion_tecnica" TEXT,
ADD COLUMN     "tiempo_uso" VARCHAR(100);

-- CreateTable
CREATE TABLE "comunidad_mensajes" (
    "id" SERIAL NOT NULL,
    "usuario_id" INTEGER NOT NULL,
    "contenido" TEXT,
    "tipo" VARCHAR(50) NOT NULL DEFAULT 'texto',
    "fecha_envio" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "comunidad_mensajes_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "comunidad_mensajes_usuario_id_idx" ON "comunidad_mensajes"("usuario_id");

-- AddForeignKey
ALTER TABLE "comunidad_mensajes" ADD CONSTRAINT "comunidad_mensajes_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;
