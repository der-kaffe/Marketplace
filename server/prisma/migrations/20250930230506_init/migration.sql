-- CreateTable
CREATE TABLE "cuentas" (
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
CREATE TABLE "roles" (
    "id" SERIAL NOT NULL,
    "nombre" VARCHAR(50) NOT NULL,

    CONSTRAINT "roles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "estados_usuario" (
    "id" SERIAL NOT NULL,
    "nombre" VARCHAR(50) NOT NULL,

    CONSTRAINT "estados_usuario_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "categorias" (
    "id" SERIAL NOT NULL,
    "nombre" VARCHAR(255) NOT NULL,
    "categoria_padre_id" INTEGER,

    CONSTRAINT "categorias_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "estados_producto" (
    "id" SERIAL NOT NULL,
    "nombre" VARCHAR(50) NOT NULL,

    CONSTRAINT "estados_producto_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "productos" (
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
CREATE TABLE "imagenes_producto" (
    "id" SERIAL NOT NULL,
    "producto_id" INTEGER NOT NULL,
    "url_imagen" BYTEA,

    CONSTRAINT "imagenes_producto_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "estados_transaccion" (
    "id" SERIAL NOT NULL,
    "nombre" VARCHAR(50) NOT NULL,

    CONSTRAINT "estados_transaccion_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "transacciones" (
    "id" SERIAL NOT NULL,
    "producto_id" INTEGER NOT NULL,
    "comprador_id" INTEGER NOT NULL,
    "vendedor_id" INTEGER NOT NULL,
    "fecha" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "estado_id" INTEGER NOT NULL,

    CONSTRAINT "transacciones_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "calificaciones" (
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
CREATE TABLE "carrito" (
    "id" SERIAL NOT NULL,
    "usuario_id" INTEGER NOT NULL,
    "producto_id" INTEGER NOT NULL,
    "cantidad" INTEGER NOT NULL,

    CONSTRAINT "carrito_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "mensajes" (
    "id" SERIAL NOT NULL,
    "remitente_id" INTEGER NOT NULL,
    "destinatario_id" INTEGER NOT NULL,
    "contenido" TEXT,
    "fecha_envio" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "leido" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "mensajes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "estados_reporte" (
    "id" SERIAL NOT NULL,
    "nombre" VARCHAR(50) NOT NULL,

    CONSTRAINT "estados_reporte_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "reportes" (
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
CREATE TABLE "actividad_usuario" (
    "id" SERIAL NOT NULL,
    "usuario_id" INTEGER NOT NULL,
    "accion" VARCHAR(50),
    "detalles" TEXT,
    "fecha" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "actividad_usuario_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notificaciones" (
    "id" SERIAL NOT NULL,
    "usuario_id" INTEGER NOT NULL,
    "tipo" VARCHAR(50),
    "mensaje" TEXT,
    "leido" BOOLEAN NOT NULL DEFAULT false,
    "fecha" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notificaciones_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "publicaciones" (
    "id" SERIAL NOT NULL,
    "titulo" VARCHAR(255),
    "cuerpo" TEXT,
    "usuario_id" INTEGER NOT NULL,
    "estado" VARCHAR(255),
    "fecha" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "publicaciones_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "foros" (
    "id" SERIAL NOT NULL,
    "nombre" VARCHAR(255) NOT NULL,
    "descripcion" TEXT,
    "creador_id" INTEGER NOT NULL,
    "fecha_creacion" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "foros_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "publicaciones_foro" (
    "id" SERIAL NOT NULL,
    "foro_id" INTEGER NOT NULL,
    "autor_id" INTEGER NOT NULL,
    "titulo" VARCHAR(255),
    "contenido" TEXT,
    "fecha" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "publicaciones_foro_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "comentarios_publicacion" (
    "id" SERIAL NOT NULL,
    "publicacion_id" INTEGER NOT NULL,
    "autor_id" INTEGER NOT NULL,
    "contenido" TEXT,
    "fecha" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "comentarios_publicacion_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ubicaciones" (
    "id" SERIAL NOT NULL,
    "usuario_id" INTEGER NOT NULL,
    "nombre_lugar" VARCHAR(255),
    "descripcion" TEXT,

    CONSTRAINT "ubicaciones_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "resumen_usuario" (
    "usuario_id" INTEGER NOT NULL,
    "total_productos" INTEGER NOT NULL DEFAULT 0,
    "total_ventas" INTEGER NOT NULL DEFAULT 0,
    "total_compras" INTEGER NOT NULL DEFAULT 0,
    "promedio_calificacion" DECIMAL(3,2) NOT NULL DEFAULT 0.00,

    CONSTRAINT "resumen_usuario_pkey" PRIMARY KEY ("usuario_id")
);

-- CreateTable
CREATE TABLE "seguidores" (
    "usuario_sigue_id" INTEGER NOT NULL,
    "usuario_seguido_id" INTEGER NOT NULL,
    "fecha" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "seguidores_pkey" PRIMARY KEY ("usuario_sigue_id","usuario_seguido_id")
);

-- CreateTable
CREATE TABLE "metricas_diarias" (
    "id" SERIAL NOT NULL,
    "fecha_metricas" DATE NOT NULL,
    "usuarios_activos" INTEGER NOT NULL DEFAULT 0,
    "nuevos_usuarios" INTEGER NOT NULL DEFAULT 0,
    "productos_creados" INTEGER NOT NULL DEFAULT 0,
    "transacciones_completadas" INTEGER NOT NULL DEFAULT 0,
    "mensajes_enviados" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "metricas_diarias_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "cuentas_correo_key" ON "cuentas"("correo");

-- CreateIndex
CREATE UNIQUE INDEX "cuentas_usuario_key" ON "cuentas"("usuario");

-- CreateIndex
CREATE INDEX "cuentas_rol_id_idx" ON "cuentas"("rol_id");

-- CreateIndex
CREATE INDEX "cuentas_estado_id_idx" ON "cuentas"("estado_id");

-- CreateIndex
CREATE INDEX "categorias_categoria_padre_id_idx" ON "categorias"("categoria_padre_id");

-- CreateIndex
CREATE INDEX "productos_estado_id_idx" ON "productos"("estado_id");

-- CreateIndex
CREATE INDEX "productos_categoria_id_idx" ON "productos"("categoria_id");

-- CreateIndex
CREATE INDEX "productos_vendedor_id_idx" ON "productos"("vendedor_id");

-- CreateIndex
CREATE INDEX "imagenes_producto_producto_id_idx" ON "imagenes_producto"("producto_id");

-- CreateIndex
CREATE INDEX "transacciones_producto_id_idx" ON "transacciones"("producto_id");

-- CreateIndex
CREATE INDEX "transacciones_comprador_id_idx" ON "transacciones"("comprador_id");

-- CreateIndex
CREATE INDEX "transacciones_vendedor_id_idx" ON "transacciones"("vendedor_id");

-- CreateIndex
CREATE INDEX "transacciones_estado_id_idx" ON "transacciones"("estado_id");

-- CreateIndex
CREATE INDEX "calificaciones_transaccion_id_idx" ON "calificaciones"("transaccion_id");

-- CreateIndex
CREATE INDEX "calificaciones_calificador_id_idx" ON "calificaciones"("calificador_id");

-- CreateIndex
CREATE INDEX "calificaciones_calificado_id_idx" ON "calificaciones"("calificado_id");

-- CreateIndex
CREATE INDEX "carrito_usuario_id_idx" ON "carrito"("usuario_id");

-- CreateIndex
CREATE INDEX "carrito_producto_id_idx" ON "carrito"("producto_id");

-- CreateIndex
CREATE INDEX "mensajes_remitente_id_idx" ON "mensajes"("remitente_id");

-- CreateIndex
CREATE INDEX "mensajes_destinatario_id_idx" ON "mensajes"("destinatario_id");

-- CreateIndex
CREATE INDEX "reportes_reportante_id_idx" ON "reportes"("reportante_id");

-- CreateIndex
CREATE INDEX "reportes_usuario_reportado_id_idx" ON "reportes"("usuario_reportado_id");

-- CreateIndex
CREATE INDEX "reportes_producto_id_idx" ON "reportes"("producto_id");

-- CreateIndex
CREATE INDEX "reportes_estado_id_idx" ON "reportes"("estado_id");

-- CreateIndex
CREATE INDEX "actividad_usuario_usuario_id_idx" ON "actividad_usuario"("usuario_id");

-- CreateIndex
CREATE INDEX "notificaciones_usuario_id_idx" ON "notificaciones"("usuario_id");

-- CreateIndex
CREATE INDEX "publicaciones_usuario_id_idx" ON "publicaciones"("usuario_id");

-- CreateIndex
CREATE INDEX "foros_creador_id_idx" ON "foros"("creador_id");

-- CreateIndex
CREATE INDEX "publicaciones_foro_foro_id_idx" ON "publicaciones_foro"("foro_id");

-- CreateIndex
CREATE INDEX "publicaciones_foro_autor_id_idx" ON "publicaciones_foro"("autor_id");

-- CreateIndex
CREATE INDEX "comentarios_publicacion_publicacion_id_idx" ON "comentarios_publicacion"("publicacion_id");

-- CreateIndex
CREATE INDEX "comentarios_publicacion_autor_id_idx" ON "comentarios_publicacion"("autor_id");

-- CreateIndex
CREATE INDEX "ubicaciones_usuario_id_idx" ON "ubicaciones"("usuario_id");

-- CreateIndex
CREATE INDEX "seguidores_usuario_seguido_id_idx" ON "seguidores"("usuario_seguido_id");

-- AddForeignKey
ALTER TABLE "cuentas" ADD CONSTRAINT "cuentas_rol_id_fkey" FOREIGN KEY ("rol_id") REFERENCES "roles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cuentas" ADD CONSTRAINT "cuentas_estado_id_fkey" FOREIGN KEY ("estado_id") REFERENCES "estados_usuario"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "categorias" ADD CONSTRAINT "categorias_categoria_padre_id_fkey" FOREIGN KEY ("categoria_padre_id") REFERENCES "categorias"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "productos" ADD CONSTRAINT "productos_categoria_id_fkey" FOREIGN KEY ("categoria_id") REFERENCES "categorias"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "productos" ADD CONSTRAINT "productos_vendedor_id_fkey" FOREIGN KEY ("vendedor_id") REFERENCES "cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "productos" ADD CONSTRAINT "productos_estado_id_fkey" FOREIGN KEY ("estado_id") REFERENCES "estados_producto"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "imagenes_producto" ADD CONSTRAINT "imagenes_producto_producto_id_fkey" FOREIGN KEY ("producto_id") REFERENCES "productos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transacciones" ADD CONSTRAINT "transacciones_producto_id_fkey" FOREIGN KEY ("producto_id") REFERENCES "productos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transacciones" ADD CONSTRAINT "transacciones_comprador_id_fkey" FOREIGN KEY ("comprador_id") REFERENCES "cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transacciones" ADD CONSTRAINT "transacciones_vendedor_id_fkey" FOREIGN KEY ("vendedor_id") REFERENCES "cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transacciones" ADD CONSTRAINT "transacciones_estado_id_fkey" FOREIGN KEY ("estado_id") REFERENCES "estados_transaccion"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "calificaciones" ADD CONSTRAINT "calificaciones_transaccion_id_fkey" FOREIGN KEY ("transaccion_id") REFERENCES "transacciones"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "calificaciones" ADD CONSTRAINT "calificaciones_calificador_id_fkey" FOREIGN KEY ("calificador_id") REFERENCES "cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "calificaciones" ADD CONSTRAINT "calificaciones_calificado_id_fkey" FOREIGN KEY ("calificado_id") REFERENCES "cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "carrito" ADD CONSTRAINT "carrito_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "carrito" ADD CONSTRAINT "carrito_producto_id_fkey" FOREIGN KEY ("producto_id") REFERENCES "productos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mensajes" ADD CONSTRAINT "mensajes_remitente_id_fkey" FOREIGN KEY ("remitente_id") REFERENCES "cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mensajes" ADD CONSTRAINT "mensajes_destinatario_id_fkey" FOREIGN KEY ("destinatario_id") REFERENCES "cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reportes" ADD CONSTRAINT "reportes_reportante_id_fkey" FOREIGN KEY ("reportante_id") REFERENCES "cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reportes" ADD CONSTRAINT "reportes_usuario_reportado_id_fkey" FOREIGN KEY ("usuario_reportado_id") REFERENCES "cuentas"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reportes" ADD CONSTRAINT "reportes_producto_id_fkey" FOREIGN KEY ("producto_id") REFERENCES "productos"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reportes" ADD CONSTRAINT "reportes_estado_id_fkey" FOREIGN KEY ("estado_id") REFERENCES "estados_reporte"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "actividad_usuario" ADD CONSTRAINT "actividad_usuario_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notificaciones" ADD CONSTRAINT "notificaciones_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "publicaciones" ADD CONSTRAINT "publicaciones_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "foros" ADD CONSTRAINT "foros_creador_id_fkey" FOREIGN KEY ("creador_id") REFERENCES "cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "publicaciones_foro" ADD CONSTRAINT "publicaciones_foro_foro_id_fkey" FOREIGN KEY ("foro_id") REFERENCES "foros"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "publicaciones_foro" ADD CONSTRAINT "publicaciones_foro_autor_id_fkey" FOREIGN KEY ("autor_id") REFERENCES "cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "comentarios_publicacion" ADD CONSTRAINT "comentarios_publicacion_publicacion_id_fkey" FOREIGN KEY ("publicacion_id") REFERENCES "publicaciones_foro"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "comentarios_publicacion" ADD CONSTRAINT "comentarios_publicacion_autor_id_fkey" FOREIGN KEY ("autor_id") REFERENCES "cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ubicaciones" ADD CONSTRAINT "ubicaciones_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "resumen_usuario" ADD CONSTRAINT "resumen_usuario_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "seguidores" ADD CONSTRAINT "seguidores_usuario_sigue_id_fkey" FOREIGN KEY ("usuario_sigue_id") REFERENCES "cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "seguidores" ADD CONSTRAINT "seguidores_usuario_seguido_id_fkey" FOREIGN KEY ("usuario_seguido_id") REFERENCES "cuentas"("id") ON DELETE CASCADE ON UPDATE CASCADE;
