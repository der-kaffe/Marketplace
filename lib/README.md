# Descripción de directorios

**models**: Clases para mapear datos del backend
**screens**: Pantallas de la app
**widgets**: Componentes reutilizables
**services**: Conexión con API / HTTP requests

# 🏠 Pantalla Principal (HomeScreen) - Guía para Desarrolladores

## 🎯 Descripción General

`HomeScreen` es la pantalla principal y el "corazón" de la aplicación. Es un `StatefulWidget` complejo diseñado para ser la principal puerta de entrada de los usuarios para descubrir productos.

Sus responsabilidades clave son:
-   Mostrar un listado paginado de todos los productos disponibles.
-   Permitir la **búsqueda** en tiempo real.
-   Permitir el **filtrado** por categoría y rango de precios.
-   Manejar **acciones rápidas** (favoritos, visibilidad del producto).
-   **Actualizarse automáticamente** cuando el usuario regresa a ella.

---

## 🏗️ Arquitectura y Servicios Clave

Esta pantalla no funciona sola; depende de varios servicios y componentes para gestionar los datos y la navegación:

* **`ProductService`**: Es el servicio principal para obtener datos. `HomeScreen` lo usa para:
    * `fetchProducts()`: Obtener la lista paginada de productos.
    * `toggleVisibility()`: Ocultar o mostrar una publicación propia.
* **`AuthService`**: Se usa para obtener el token de autenticación y, principalmente, para:
    * `apiClient.getCategoriesFromApi()`: Cargar la lista de categorías.
    * `apiClient.getProductFavorites()`: Saber qué productos tiene el usuario en favoritos.
    * `apiClient.addProductFavorite()` / `removeProductFavorite()`: Manejar las acciones de favoritos.
* **`RouteAware` (de Flutter)**: Se usa para "escuchar" la navegación. Cuando el usuario vuelve a esta pantalla (ej. después de crear un post), `didPopNext()` se activa y fuerza una recarga.
* **`ProductDetailModal`**: Es el `ModalBottomSheet` que se abre al tocar una `ProductCard` para ver los detalles.

---

## 🧠 Gestión del Estado (El Núcleo)

La complejidad de esta pantalla radica en cómo maneja múltiples listas de productos para permitir la carga infinita y los filtros sin perder datos.

### Las 3 Listas de Productos:

1.  **`_originalProducts` (La "Fuente de Verdad")**
    * **Propósito**: Almacena una copia maestra de *todos* los productos que se han cargado desde la API, página por página.
    * **Uso**: Es la lista **base** sobre la cual se aplican todos los filtros (`_applyCombinedFilter`) y búsquedas (`_searchProductsByText`). **Esta lista nunca es modificada por los filtros.**

2.  **`_filteredProducts` (La "Lista Visible")**
    * **Propósito**: Es la lista que la UI (`GridView`) renderiza en la pantalla.
    * **Uso**: Su contenido cambia constantemente:
        * Si no hay filtros, se le *añaden* nuevos productos del scroll infinito.
        * Si se aplica un filtro, esta lista se *reemplaza* por completo con el resultado de filtrar `_originalProducts`.

3.  **`_allProducts` (Estado Acumulativo)**
    * **Propósito**: Similar a `_originalProducts`, actúa como un acumulador de todas las páginas cargadas.
    * *(Nota: La lógica de `forceRefreshProducts` limpia las 3 listas, asegurando una recarga completa).*

### Control de Paginación:

* **`_page`**: El número de la página actual a solicitar a la API. Se incrementa en `_loadMoreProducts`.
* **`_hasLoadedAllProducts`**: Un `bool` que se vuelve `true` cuando la API devuelve una página vacía o con menos productos que el límite. Esto **detiene** el scroll infinito para evitar llamadas innecesarias a la API.

### Estado de Filtros:

* **`_selectedCategoryId`**: Almacena el ID de la categoría seleccionada.
* **`_precioMinimo` / `_precioMaximo`**: Almacenan el rango de precio del filtro.

---

## 🔄 Flujo de Datos (Métodos Clave)

### Carga y Refresco de Datos

* **`initState()`**:
    1.  Inicia la carga de categorías (`_loadCategories`).
    2.  Inicia la carga de favoritos (`_loadFavorites`).
    3.  Llama a `_loadMoreProducts()` por primera vez para cargar la página 1.
    4.  Añade un *listener* al `_scrollController` para detectar el final de la página.

* **`_loadMoreProducts()` (El Motor de Carga)**:
    1.  Verifica si ya está cargando (`_isLoadingProducts`) o si ya se cargó todo (`_hasLoadedAllProducts`). Si es así, se detiene.
    2.  Pone `_isLoadingProducts = true` (para mostrar la animación de carga).
    3.  Llama a `_productService.fetchProducts(page: _page)`.
    4.  Si la respuesta `newProducts` está vacía, activa `_hasLoadedAllProducts = true`.
    5.  Añade `newProducts` a las listas `_originalProducts`, `_allProducts` y `_filteredProducts`.
    6.  Incrementa `_page` para la próxima llamada.
    7.  En un bloque `finally`, siempre pone `_isLoadingProducts = false` (para ocultar la animación, incluso si hubo un error).

* **`forceRefreshProducts()` (El Botón de "Reset")**:
    1.  Limpia **todas** las listas (`_originalProducts`, `_filteredProducts`, `_allProducts`).
    2.  Resetea **todos** los filtros (`_selectedCategoryId`, `_precioMinimo`, etc.).
    3.  Resetea **toda** la paginación (`_page = 1`, `_hasLoadedAllProducts = false`).
    4.  Llama a `_loadMoreProducts()` para empezar de cero.
    5.  Es usado por el `RefreshIndicator` (deslizar para recargar).

* **`didPopNext()` (El Refresco "Inteligente")**:
    1.  Es un método de `RouteAware`. Se activa solo cuando el usuario *regresa* a esta pantalla (ej. después de cerrar `NewPostScreen` o `ProductDetailModal`).
    2.  Llama a `forceRefreshProducts()` para asegurar que cualquier cambio (un post nuevo, un post borrado) se refleje inmediatamente en la lista.

* **`_removeProductFromUI(productId)`**:
    1.  Se usa cuando el usuario borra un producto desde el `ProductDetailModal`.
    2.  El modal devuelve el `deletedProductId` y este método lo usa para eliminar el producto de las listas `_originalProducts` y `_filteredProducts` **localmente**.
    3.  Esto es mucho más rápido que `forceRefreshProducts` porque evita una llamada a la API.

### Filtros y Búsqueda

* **`_applyCombinedFilter()`**:
    1.  Es el "cerebro" de los filtros.
    2.  Toma `_originalProducts` como la lista maestra.
    3.  Filtra la lista en memoria basándose en `_selectedCategoryId` y el rango `_precioMinimo` / `_precioMaximo`.
    4.  Reemplaza el contenido de `_filteredProducts` con los resultados.

* **`_searchProductsByText(query)`**:
    1.  Toma el `query` del usuario.
    2.  Lo "normaliza" con `_normalizeText()` (quita tildes, pasa a minúsculas).
    3.  Filtra `_originalProducts` buscando el query normalizado en `title` y `description`.
    4.  Reemplaza `_filteredProducts` con los resultados.
    5.  Si el `query` está vacío, llama a `_applyCombinedFilter()` para restaurar los filtros activos.

* **`_clearCategoryFilter()`**:
    1.  Resetea *todos* los filtros (categoría y precio).
    2.  Restaura `_filteredProducts` a su estado original (haciendo una copia de `_originalProducts`).

### Acciones de la UI

* **`_toggleFavorite(product)`**:
    1.  Llama a la API (`apiClient.addProductFavorite` o `remove...`).
    2.  Si tiene éxito, actualiza `_favoriteProductIds` (un `Set<String>`).
    3.  Llama a `setState()` para que el icono del corazón en la `ProductCard` se actualice instantáneamente.

* **`_toggleProductVisibility(product)`**:
    1.  Llama a la API (`_productService.toggleVisibility`).
    2.  Si tiene éxito, actualiza el objeto `product` en las listas `_originalProducts` y `_filteredProducts` usando `copyWith(isAvailable: newVisibility)`.
    3.  Llama a `setState()` para que la `ProductCard` cambie su apariencia (ej. icono de visibilidad).


<!-- ************************************************************************ -->

# 📝 Pantalla de Nueva Publicación (NewPostScreen) - Guía para Desarrolladores

## 🎯 Descripción General

`NewPostScreen` es una pantalla con estado (`StatefulWidget`) dedicada a la creación de nuevas publicaciones de productos. Proporciona un formulario completo para que los usuarios (Vendedores o Clientes) ingresen todos los detalles de un artículo que desean vender, incluyendo imágenes, detalles técnicos y precio.

Esta pantalla es crucial para el ecosistema, ya que es el punto de entrada para nuevos productos en el marketplace. Además, maneja la lógica de auto-promoción de "Cliente" a "Vendedor" en el backend.

---

## 🏗️ Arquitectura y Servicios Clave

* **`ProductService`**: Es el servicio principal para interactuar con la API de productos. Se usa para:
    * `fetchCategories()`: Obtener la lista de categorías disponibles para el `DropdownButtonFormField`.
    * `createProduct()`: Enviar todos los datos del formulario, incluyendo la imagen en Base64, al backend para crear el nuevo producto.
* **`AuthService`**: Se utiliza para obtener el `token` de autenticación necesario para la subida de imágenes y la creación de productos.
* **`ImagePicker`**: Paquete de Flutter (`image_picker`) utilizado para abrir la galería del usuario y seleccionar una foto para el producto.
* **`Form` Widget**: El formulario (`GlobalKey<FormState>`) es el núcleo de la pantalla, gestionando la validación de todos los campos (título, descripción, precio, etc.).

---

## 🧠 Gestión del Estado (`_NewPostScreenState`)

El estado de esta pantalla gestiona principalmente los controladores del formulario y el estado de carga.

* **`_formKey`**: `GlobalKey` para identificar y validar el formulario.
* **`TextEditingController`**: Se usa un controlador para cada campo de texto (`_titleCtrl`, `_descCtrl`, `_priceCtrl`, `_quantityCtrl`, `_informacionTecnicaCtrl`, `_tiempoUsoCtrl`) para capturar la entrada del usuario.
* **`_categories` y `_isLoadingCategories`**: Almacenan la lista de categorías obtenida de la API y controlan el indicador de carga del dropdown.
* **`_selectedCategoryId` y `_estadoProducto`**: Almacenan el valor seleccionado en los `DropdownButtonFormField` de categoría y estado.
* **`_selectedImageFile`**: Un objeto `File` que almacena la imagen seleccionada desde la galería, lista para ser convertida y subida.
* **`_isLoading` y `_isUploadingImage`**: Banderas `bool` para gestionar los indicadores de carga. `_isUploadingImage` es específico para el proceso de conversión a Base64, mientras que `_isLoading` bloquea todo el formulario durante el envío a la API.

---

## 🔄 Flujo de Datos (Métodos Clave)

### Carga Inicial

* **`initState()`**: Llama inmediatamente a `_loadCategories()` para llenar el dropdown de categorías apenas se construye la pantalla.

### Selección y Carga de Imagen

* **`_pickImage()`**:
    1.  Utiliza `ImagePicker.pickImage()` para abrir la galería del usuario.
    2.  Pide imágenes con calidad reducida (`imageQuality: 70`) y tamaño máximo (`maxWidth: 1024`) para optimizar la subida.
    3.  Si el usuario selecciona un archivo, lo almacena en la variable de estado `_selectedImageFile`, lo que actualiza la UI para mostrar la vista previa.

* **`_uploadImage(File imageFile)`**:
    1.  Este método **no sube la imagen a un bucket**, sino que la **convierte a Base64** para ser enviada en el cuerpo JSON de la petición de creación de producto.
    2.  Establece `_isUploadingImage = true`.
    3.  Lee el `imageFile` como bytes (`readAsBytes()`).
    4.  Codifica los bytes a `base64Encode()`.
    5.  Detecta el `mimeType` (ej. `image/jpeg`) basándose en la extensión del archivo.
    6.  Retorna un **Data URL** (ej. `data:image/jpeg;base64,iVBORw0...`).
    7.  Establece `_isUploadingImage = false` en el `finally`.

### Creación del Producto

* **`_createProduct()`**:
    1.  Es el método principal, llamado al presionar "Publicar producto".
    2.  Valida el `_formKey`.
    3.  Verifica que se haya seleccionado una categoría (`_selectedCategoryId != null`).
    4.  Verifica que se haya seleccionado una imagen (`_selectedImageFile != null`).
    5.  Establece `_isLoading = true` (bloqueando el formulario).
    6.  Llama a `_uploadImage()` para obtener el string Base64.
    7.  Llama a `_productService.createProduct()` pasando todos los datos de los controladores, incluyendo el string Base64 en el campo `imageUrl`.
    8.  Si tiene éxito, llama a `_showSuccessSheet()`.
    9.  Si falla, muestra un `SnackBar` de error.
    10. En `finally`, establece `_isLoading = false`.

### Flujo Post-Publicación

* **`_showSuccessSheet()`**:
    1.  Muestra un `ModalBottomSheet` de éxito que **no se puede cerrar** deslizando (`isDismissible: false`).
    2.  Ofrece dos opciones: "Crear otro" o "Ir al inicio".
    3.  **"Crear otro"**: Cierra el modal (`Navigator.pop(dialogContext, false)`), limpia todos los controladores y variables de estado (reseteando el formulario).
    4.  **"Ir al inicio"**: Cierra el modal (`Navigator.pop(dialogContext, true)`) y devuelve `true`.
    5.  `_createProduct` recibe este `true` y ejecuta `context.go('/home')` para navegar al inicio. Esto **dispara el `didPopNext()` en `HomeScreen`**, forzando la recarga de productos.