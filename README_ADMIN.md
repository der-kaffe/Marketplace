# README: Módulo de Administración

Este documento detalla la arquitectura, funcionalidad y flujos del Panel de Administración de la aplicación.

## 1. 📖 Resumen General

El Módulo de Administración es una sección protegida de la aplicación diseñada para usuarios con el rol de "Administrador". Proporciona herramientas para moderar usuarios, gestionar reportes y monitorear la salud del sistema.

La funcionalidad se divide en tres componentes principales:
* **Gestión de Usuarios:** Ver, crear, editar, banear y eliminar usuarios.
* **Gestión de Reportes:** Revisar y actualizar el estado de los reportes enviados por los usuarios.
* **Métricas del Sistema:** Visualizar estadísticas clave sobre el uso de la plataforma.

## 2. 🔐 Arquitectura y Seguridad

El módulo consta de dos partes: el **Frontend (Flutter)**, que son las pantallas de la interfaz, y el **Backend (Express)**, que son los endpoints de la API que proveen los datos.

### Seguridad del Backend

Toda la API de administración está protegida por dos *middlewares* en el backend:

1.  **`authenticateToken`**: Asegura que el usuario haya iniciado sesión y tenga un token válido.
2.  **`requireAdmin`**: Verifica que el usuario autenticado tenga el rol de "Administrador".

Si un usuario normal intenta acceder a estos endpoints, recibirá un error `403 Forbidden` (Acceso denegado).

## 3. 📱 Frontend (Flutter)

La interfaz de administrador se compone de varias pantallas y widgets que consumen la API del backend.

### Archivos Principales

* **`admin_menu_page.dart`**: Es el centro de navegación principal. Muestra los botones para acceder a las diferentes secciones (Usuarios, Reportes, Métricas).
* **`admin_users_page.dart`**: Muestra la lista de todos los usuarios de la plataforma. Permite realizar operaciones CRUD (Crear, Leer, Actualizar, Eliminar) sobre ellos.
* **`admin_reports_page.dart`**: Muestra una lista de todos los reportes (de productos y de usuarios). Indica el estado de cada uno (Pendiente, Revisado, etc.).
* **`admin_report_detail_page.dart`**: Muestra la información detallada de un solo reporte, incluyendo quién reportó, el motivo y el ítem reportado.
* **`admin_metrics_page.dart`**: Muestra un dashboard con las estadísticas del sistema.

### Flujo de Navegación (GoRouter)

El acceso se da (presumiblemente) desde la pantalla de perfil del usuario. Si el usuario es administrador, ve un botón que lo lleva a `/admin`.

* `context.push('/admin')` → Muestra `AdminMenuPage`.
* Desde el menú:
    * `context.push('/admin/users')` → Muestra `AdminUsersPage`.
    * `context.push('/admin/reports')` → Muestra `AdminReportsPage`.
    * `context.push('/admin/metrics')` → Muestra `AdminMetricsPage`.
* Desde la lista de reportes:
    * `context.push('/admin/reports/:id')` → Muestra `ReportDetailPage` con el ID del reporte.

## 4. ⚙️ Backend (API Endpoints)

El backend expone rutas específicas para que el frontend de administración las consuma.

### Gestión de Usuarios

**Archivo:** `admin.js`
**Prefijo:** `/api/admin`

* **`GET /api/admin/users`**
    * **Descripción:** Obtiene la lista completa de usuarios.
    * **Usado en:** `admin_users_page.dart` para poblar la lista inicial.
* **`POST /api/admin/users`**
    * **Descripción:** Crea un nuevo usuario. Recibe `nombre`, `correo`, `contrasena`, etc., en el `body`.
    * **Usado en:** `CreateUserDialog` (invocado desde `admin_users_page.dart`).
* **`PUT /api/admin/:id`**
    * **Descripción:** Actualiza la información de un usuario existente.
    * **Usado en:** `EditUserDialog` (invocado desde `admin_users_page.dart`).
* **`PATCH /api/admin/users/:id/ban`**
    * **Descripción:** Cambia el estado de un usuario (banea o desbanea). Espera un `body` con `{"banned": true}` o `{"banned": false}`.
    * **Usado en:** `admin_users_page.dart`, en el método `_toggleBanStatus`.
* **`DELETE /api/admin/users/:id`**
    * **Descripción:** Elimina permanentemente a un usuario de la base de datos.
    * **Usado en:** `admin_users_page.dart`, en el método `_onDelete`.

### Gestión de Reportes

**Archivo:** `reports.js`
**Prefijo:** `/api/reports`

* **`GET /api/reports`**
    * **Descripción:** Obtiene la lista de todos los reportes (protegido por `requireAdmin`).
    * **Usado en:** `admin_reports_page.dart` para poblar la lista.
* **`GET /api/reports/:id`**
    * **Descripción:** Obtiene los detalles completos de un solo reporte, incluyendo información del reportante, el reportado y el producto (si aplica).
    * **Usado en:** `admin_report_detail_page.dart` en `_fetchReport()`.
* **`PATCH /api/reports/:id`**
    * **Descripción:** Actualiza el estado de un reporte. Espera un `body` con `{"estadoId": nuevoId}`.
    * **Usado en:** `admin_report_detail_page.dart` en `_toggleStatus()`, donde cambia entre estado 1 (Pendiente) y 2 (Revisado).

### Métricas del Sistema

**Archivo:** `admin.js`
**Prefijo:** `/api/admin`

* **`GET /api/admin/metrics`**
    * **Descripción:** Realiza varias consultas a la base de datos para contar usuarios totales, productos, reportes abiertos, transacciones completadas y usuarios activos.
    * **Usado en:** `admin_metrics_page.dart` en `_fetchMetrics()` para obtener los datos del dashboard.

## 5. 🧪 Cómo Probar

1.  Asegúrate de que tu cuenta de usuario en la base de datos tenga el `rolId` correspondiente al de "Administrador".
2.  Inicia sesión en la aplicación de Flutter.
3.  Navega a tu pantalla de Perfil. Debería aparecer el botón "Panel de Administrador" (basado en la lógica del `AuthService().isAdmin`).
4.  Ingresa al panel y navega a **"Administrar Usuarios"**. La lista de usuarios debe cargar. Prueba banear o desbanear un usuario de prueba.
5.  Navega a **"Ver Reportes"**. La lista de reportes debe cargar.
6.  Entra al detalle de un reporte. Cambia su estado de "Pendiente" a "Revisado".
7.  Regresa a la lista de reportes. El reporte actualizado debería cambiar su estado visualmente (la lógica de `_updateReportStatus` en `admin_reports_page.dart` maneja esto).
8.  Navega a **"Ver Métricas"**. Los contadores deben mostrar valores numéricos.