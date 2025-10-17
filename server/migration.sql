-- CreateTable
CREATE TABLE "public"."actividad_usuario" (
    "id" SERIAL NOT NULL,
    "usuario_id" INTEGER NOT NULL,
    "accion" VARCHAR(50),
    "detalles" TEXT,
    "fecha" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "actividad_usuario_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."calificaciones" (
    "id" SERIAL NOT NULL,
    "transaccion_id" INTEGER NOT NULL,
    "calificador_id" INTEGER NOT NULL,
    "calificado_id" INTEGER NOT NULL,
    "puntuacion" DECIMAL(3,2),
    "comentario" TEXT,
    "fecha" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "calificaciones_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."carrito" (
    "id" SERIAL NOT NULL,
    "usuario_id" INTEGER NOT NULL,
    "producto_id" INTEGER NOT NULL,
    "cantidad" INTEGER NOT NULL,

    CONSTRAINT "carrito_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."categorias" (
    "id" SERIAL NOT NULL,
    "nombre" VARCHAR(255) NOT NULL,
    "categoria_padre_id" INTEGER,

    CONSTRAINT "categorias_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."comentarios_publicacion" (
    "id" SERIAL NOT NULL,
    "publicacion_id" INTEGER NOT NULL,
    "autor_id" INTEGER NOT NULL,
    "contenido" TEXT,
    "fecha" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "comentarios_publicacion_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."cuentas" (
    "id" SERIAL NOT NULL,
    "nombre" VARCHAR(50) NOT NULL,
    "apellido" VARCHAR(50),
    "correo" VARCHAR(255) NOT NULL,
    "usuario" VARCHAR(255) NOT NULL,
    "contrasena" VARCHAR(255) NOT NULL,
    "rol_id" INTEGER NOT NULL,
    "estado_id" INTEGER NOT NULL,
    "fecha_registro" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "campus" VARCHAR(100),
    "reputacion" DECIMAL(5,2) NOT NULL DEFAULT 0.00,

    CONSTRAINT "cuentas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."estados_producto" (
    "id" SERIAL NOT NULL,
    "nombre" VARCHAR(50) NOT NULL,

    CONSTRAINT "estados_producto_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."estados_reporte" (
    "id" SERIAL NOT NULL,
    "nombre" VARCHAR(50) NOT NULL,

    CONSTRAINT "estados_reporte_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."estados_transaccion" (
    "id" SERIAL NOT NULL,
    "nombre" VARCHAR(50) NOT NULL,

    CONSTRAINT "estados_transaccion_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."estados_usuario" (
    "id" SERIAL NOT NULL,
    "nombre" VARCHAR(50) NOT NULL,

    CONSTRAINT "estados_usuario_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."foros" (
    "id" SERIAL NOT NULL,
    "nombre" VARCHAR(255) NOT NULL,
    "descripcion" TEXT,
    "creador_id" INTEGER NOT NULL,
    "fecha_creacion" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "foros_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."imagenes_producto" (
    "id" SERIAL NOT NULL,
    "producto_id" INTEGER NOT NULL,
    "url_imagen" BYTEA,

    CONSTRAINT "imagenes_producto_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."mensajes" (
    "id" SERIAL NOT NULL,
    "remitente_id" INTEGER NOT NULL,
    "destinatario_id" INTEGER NOT NULL,
    "contenido" TEXT,
    "fecha_envio" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "leido" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "mensajes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."metricas_diarias" (
    "id" SERIAL NOT NULL,
    "fecha_metricas" DATE NOT NULL,
    "usuarios_activos" INTEGER NOT NULL DEFAULT 0,
    "nuevos_usuarios" INTEGER NOT NULL DEFAULT 0,
    "productos_creados" INTEGER NOT NULL DEFAULT 0,
    "transacciones_completadas" INTEGER NOT NULL DEFAULT 0,
    "mensajes_enviados" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "metricas_diarias_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."notificaciones" (
    "id" SERIAL NOT NULL,
    "usuario_id" INTEGER NOT NULL,
    "tipo" VARCHAR(50),
    "mensaje" TEXT,
    "leido" BOOLEAN NOT NULL DEFAULT false,
    "fecha" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notificaciones_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."productos" (
    "id" SERIAL NOT NULL,
    "nombre" VARCHAR(100) NOT NULL,
    "categoria_id" INTEGER,
    "vendedor_id" INTEGER NOT NULL,
    "precio_anterior" DECIMAL(10,2),
    "precio_actual" DECIMAL(10,2),
    "descripcion" TEXT,
    "calificacion" DECIMAL(3,2),
    "cantidad" INTEGER,
    "fecha_agregado" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "estado_id" INTEGER NOT NULL,

    CONSTRAINT "productos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."publicaciones" (
    "id" SERIAL NOT NULL,
    "titulo" VARCHAR(255),
    "cuerpo" TEXT,
    "usuario_id" INTEGER NOT NULL,
    "estado" VARCHAR(255),
    "fecha" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "publicaciones_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."publicaciones_foro" (
    "id" SERIAL NOT NULL,
    "foro_id" INTEGER NOT NULL,
    "autor_id" INTEGER NOT NULL,
    "titulo" VARCHAR(255),
    "contenido" TEXT,
    "fecha" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "publicaciones_foro_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."reportes" (
    "id" SERIAL NOT NULL,
    "reportante_id" INTEGER NOT NULL,
    "usuario_reportado_id" INTEGER,
    "producto_id" INTEGER,
    "motivo" TEXT,
    "fecha" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "estado_id" INTEGER NOT NULL,

    CONSTRAINT "reportes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."resumen_usuario" (
    "usuario_id" INTEGER NOT NULL,
    "total_productos" INTEGER NOT NULL DEFAULT 0,
    "total_ventas" INTEGER NOT NULL DEFAULT 0,
    "total_compras" INTEGER NOT NULL DEFAULT 0,
    "promedio_calificacion" DECIMAL(3,2) NOT NULL DEFAULT 0.00,

    CONSTRAINT "resumen_usuario_pkey" PRIMARY KEY ("usuario_id")
);

-- CreateTable
CREATE TABLE "public"."roles" (
    "id" SERIAL NOT NULL,
    "nombre" VARCHAR(50) NOT NULL,

    CONSTRAINT "roles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."seguidores" (
    "usuario_sigue_id" INTEGER NOT NULL,
    "usuario_seguido_id" INTEGER NOT NULL,
    "fecha" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "seguidores_pkey" PRIMARY KEY ("usuario_sigue_id","usuario_seguido_id")
);

-- CreateTable
CREATE TABLE "public"."transacciones" (
    "id" SERIAL NOT NULL,
    "producto_id" INTEGER NOT NULL,
    "comprador_id" INTEGER NOT NULL,
    "vendedor_id" INTEGER NOT NULL,
    "fecha" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "estado_id" INTEGER NOT NULL,

    CONSTRAINT "transacciones_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."ubicaciones" (
    "id" SERIAL NOT NULL,
    "usuario_id" INTEGER NOT NULL,
    "nombre_lugar" VARCHAR(255),
    "descripcion" TEXT,

    CONSTRAINT "ubicaciones_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "actividad_usuario_usuario_id_idx" ON "public"."actividad_usuario"("usuario_id");

-- CreateIndex
CREATE INDEX "calificaciones_transaccion_id_idx" ON "public"."calificaciones"("transaccion_id");

-- CreateIndex
CREATE INDEX "calificaciones_calificador_id_idx" ON "public"."calificaciones"("calificador_id");

-- CreateIndex
CREATE INDEX "calificaciones_calificado_id_idx" ON "public"."calificaciones"("calificado_id");

-- CreateIndex
CREATE INDEX "carrito_usuario_id_idx" ON "public"."carrito"("usuario_id");

-- CreateIndex
CREATE INDEX "carrito_producto_id_idx" ON "public"."carrito"("producto_id");

-- CreateIndex
CREATE INDEX "categorias_categoria_padre_id_idx" ON "public"."categorias"("categoria_padre_id");

-- CreateIndex
CREATE INDEX "comentarios_publicacion_publicacion_id_idx" ON "public"."comentarios_publicacion"("publicacion_id");

-- CreateIndex
CREATE INDEX "comentarios_publicacion_autor_id_idx" ON "public"."comentarios_publicacion"("autor_id");

-- CreateIndex
CREATE INDEX "cuentas_rol_id_idx" ON "public"."cuentas"("rol_id");

-- CreateIndex
CREATE INDEX "cuentas_estado_id_idx" ON "public"."cuentas"("estado_id");

-- CreateIndex
CREATE UNIQUE INDEX "cuentas_correo_key" ON "public"."cuentas"("correo");

-- CreateIndex
CREATE UNIQUE INDEX "cuentas_usuario_key" ON "public"."cuentas"("usuario");

-- CreateIndex
CREATE INDEX "foros_creador_id_idx" ON "public"."foros"("creador_id");

-- CreateIndex
CREATE INDEX "imagenes_producto_producto_id_idx" ON "public"."imagenes_producto"("producto_id");

-- CreateIndex
CREATE INDEX "mensajes_remitente_id_idx" ON "public"."mensajes"("remitente_id");

-- CreateIndex
CREATE INDEX "mensajes_destinatario_id_idx" ON "public"."mensajes"("destinatario_id");

-- CreateIndex
CREATE INDEX "notificaciones_usuario_id_idx" ON "public"."notificaciones"("usuario_id");

-- CreateIndex
CREATE INDEX "productos_estado_id_idx" ON "public"."productos"("estado_id");

-- CreateIndex
CREATE INDEX "productos_categoria_id_idx" ON "public"."productos"("categoria_id");

-- CreateIndex
CREATE INDEX "productos_vendedor_id_idx" ON "public"."productos"("vendedor_id");

-- CreateIndex
CREATE INDEX "publicaciones_usuario_id_idx" ON "public"."publicaciones"("usuario_id");

-- CreateIndex
CREATE INDEX "publicaciones_foro_foro_id_idx" ON "public"."publicaciones_foro"("foro_id");

-- CreateIndex
CREATE INDEX "publicaciones_foro_autor_id_idx" ON "public"."publicaciones_foro"("autor_id");

-- CreateIndex
CREATE INDEX "reportes_reportante_id_idx" ON "public"."reportes"("reportante_id");

-- CreateIndex
CREATE INDEX "reportes_usuario_reportado_id_idx" ON "public"."reportes"("usuario_reportado_id");

-- CreateIndex
CREATE INDEX "reportes_producto_id_idx" ON "public"."reportes"("producto_id");

-- CreateIndex
CREATE INDEX "reportes_estado_id_idx" ON "public"."reportes"("estado_id");

-- CreateIndex
CREATE INDEX "seguidores_usuario_seguido_id_idx" ON "public"."seguidores"("usuario_seguido_id");

-- CreateIndex
CREATE INDEX "transacciones_producto_id_idx" ON "public"."transacciones"("producto_id");

-- CreateIndex
CREATE INDEX "transacciones_comprador_id_idx" ON "public"."transacciones"("comprador_id");

-- CreateIndex
CREATE INDEX "transacciones_vendedor_id_idx" ON "public"."transacciones"("vendedor_id");

-- CreateIndex
CREATE INDEX "transacciones_estado_id_idx" ON "public"."transacciones"("estado_id");

-- CreateIndex
CREATE INDEX "ubicaciones_usuario_id_idx" ON "public"."ubicaciones"("usuario_id");

-- AddForeignKey
ALTER TABLE "public"."actividad_usuario" ADD CONSTRAINT "actividad_usuario_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "public"."cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."calificaciones" ADD CONSTRAINT "calificaciones_transaccion_id_fkey" FOREIGN KEY ("transaccion_id") REFERENCES "public"."transacciones"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."calificaciones" ADD CONSTRAINT "calificaciones_calificador_id_fkey" FOREIGN KEY ("calificador_id") REFERENCES "public"."cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."calificaciones" ADD CONSTRAINT "calificaciones_calificado_id_fkey" FOREIGN KEY ("calificado_id") REFERENCES "public"."cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."carrito" ADD CONSTRAINT "carrito_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "public"."cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."carrito" ADD CONSTRAINT "carrito_producto_id_fkey" FOREIGN KEY ("producto_id") REFERENCES "public"."productos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."categorias" ADD CONSTRAINT "categorias_categoria_padre_id_fkey" FOREIGN KEY ("categoria_padre_id") REFERENCES "public"."categorias"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."comentarios_publicacion" ADD CONSTRAINT "comentarios_publicacion_publicacion_id_fkey" FOREIGN KEY ("publicacion_id") REFERENCES "public"."publicaciones_foro"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."comentarios_publicacion" ADD CONSTRAINT "comentarios_publicacion_autor_id_fkey" FOREIGN KEY ("autor_id") REFERENCES "public"."cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."cuentas" ADD CONSTRAINT "cuentas_rol_id_fkey" FOREIGN KEY ("rol_id") REFERENCES "public"."roles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."cuentas" ADD CONSTRAINT "cuentas_estado_id_fkey" FOREIGN KEY ("estado_id") REFERENCES "public"."estados_usuario"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."foros" ADD CONSTRAINT "foros_creador_id_fkey" FOREIGN KEY ("creador_id") REFERENCES "public"."cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."imagenes_producto" ADD CONSTRAINT "imagenes_producto_producto_id_fkey" FOREIGN KEY ("producto_id") REFERENCES "public"."productos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."mensajes" ADD CONSTRAINT "mensajes_remitente_id_fkey" FOREIGN KEY ("remitente_id") REFERENCES "public"."cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."mensajes" ADD CONSTRAINT "mensajes_destinatario_id_fkey" FOREIGN KEY ("destinatario_id") REFERENCES "public"."cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."notificaciones" ADD CONSTRAINT "notificaciones_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "public"."cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."productos" ADD CONSTRAINT "productos_categoria_id_fkey" FOREIGN KEY ("categoria_id") REFERENCES "public"."categorias"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."productos" ADD CONSTRAINT "productos_vendedor_id_fkey" FOREIGN KEY ("vendedor_id") REFERENCES "public"."cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."productos" ADD CONSTRAINT "productos_estado_id_fkey" FOREIGN KEY ("estado_id") REFERENCES "public"."estados_producto"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."publicaciones" ADD CONSTRAINT "publicaciones_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "public"."cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."publicaciones_foro" ADD CONSTRAINT "publicaciones_foro_foro_id_fkey" FOREIGN KEY ("foro_id") REFERENCES "public"."foros"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."publicaciones_foro" ADD CONSTRAINT "publicaciones_foro_autor_id_fkey" FOREIGN KEY ("autor_id") REFERENCES "public"."cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."reportes" ADD CONSTRAINT "reportes_reportante_id_fkey" FOREIGN KEY ("reportante_id") REFERENCES "public"."cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."reportes" ADD CONSTRAINT "reportes_usuario_reportado_id_fkey" FOREIGN KEY ("usuario_reportado_id") REFERENCES "public"."cuentas"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."reportes" ADD CONSTRAINT "reportes_producto_id_fkey" FOREIGN KEY ("producto_id") REFERENCES "public"."productos"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."reportes" ADD CONSTRAINT "reportes_estado_id_fkey" FOREIGN KEY ("estado_id") REFERENCES "public"."estados_reporte"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."resumen_usuario" ADD CONSTRAINT "resumen_usuario_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "public"."cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."seguidores" ADD CONSTRAINT "seguidores_usuario_sigue_id_fkey" FOREIGN KEY ("usuario_sigue_id") REFERENCES "public"."cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."seguidores" ADD CONSTRAINT "seguidores_usuario_seguido_id_fkey" FOREIGN KEY ("usuario_seguido_id") REFERENCES "public"."cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."transacciones" ADD CONSTRAINT "transacciones_producto_id_fkey" FOREIGN KEY ("producto_id") REFERENCES "public"."productos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."transacciones" ADD CONSTRAINT "transacciones_comprador_id_fkey" FOREIGN KEY ("comprador_id") REFERENCES "public"."cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."transacciones" ADD CONSTRAINT "transacciones_vendedor_id_fkey" FOREIGN KEY ("vendedor_id") REFERENCES "public"."cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."transacciones" ADD CONSTRAINT "transacciones_estado_id_fkey" FOREIGN KEY ("estado_id") REFERENCES "public"."estados_transaccion"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."ubicaciones" ADD CONSTRAINT "ubicaciones_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "public"."cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;
