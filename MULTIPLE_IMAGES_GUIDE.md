# 🖼️ Sistema de Múltiples Imágenes - Marketplace UCT

## ✨ Nuevas Funcionalidades Implementadas

### 🎯 **Múltiples Imágenes por Producto**
- **Máximo 5 imágenes** por producto
- **Carousel interactivo** en las tarjetas de producto
- **Indicador visual** del número de imágenes
- **Drag & drop** para reorganizar (próximamente)

### 📱 **Interfaz de Usuario Mejorada**

#### **Pantalla de Nueva Publicación**
- Galería horizontal para previsualizar imágenes seleccionadas
- Botón "Agregar" para seleccionar múltiples imágenes
- Botón "X" en cada imagen para eliminarla individualmente
- Contador de imágenes (ej: "3/5 imágenes")
- Validación: mínimo 1 imagen, máximo 5 imágenes

#### **Tarjetas de Producto (ProductCard)**
- **Una imagen**: Se muestra normalmente
- **Múltiples imágenes**: Carousel con PageView
- **Indicador**: Ícono de galería + número de imágenes
- **Navegación**: Deslizar horizontalmente para ver más imágenes

## 🏗️ Arquitectura Técnica

### **Backend (Node.js + PostgreSQL)**

#### **Base de Datos**
```sql
-- Tabla ya existente: imagenes_producto
CREATE TABLE imagenes_producto (
  id SERIAL PRIMARY KEY,
  producto_id INTEGER REFERENCES productos(id) ON DELETE CASCADE,
  url_imagen VARCHAR(500), -- URLs (compatibilidad)
  imagen_data BYTEA,       -- Datos binarios de la imagen
  mime_type VARCHAR(50)    -- Tipo MIME (image/jpeg, image/png, etc.)
);
```

#### **API Endpoints**

**POST /api/products** - Crear producto con múltiples imágenes
```javascript
{
  "nombre": "iPhone 15 Pro",
  "descripcion": "Excelente estado",
  "precioActual": 800000,
  "categoriaId": 1,
  "imagenes": [
    "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQ...", // Imagen 1
    "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQ...", // Imagen 2
    "data:image/png;base64,iVBORw0KGgoAAAANSU..."  // Imagen 3
  ]
}
```

**GET /api/products/images/:productoId/:imagenId** - Servir imagen específica
```
https://api.marketplace.uct.cl/api/products/images/123/456
```

### **Frontend (Flutter)**

#### **Modelos de Datos**
```dart
class Product {
  final String id;
  final String title;
  final String? imageUrl;        // Imagen principal (compatibilidad)
  final List<String>? imagenes;  // 🆕 Múltiples imágenes
  // ...otros campos
}
```

#### **Servicios**
```dart
// ProductService - Crear producto con múltiples imágenes
await _productService.createProductWithMultipleImages(
  nombre: 'iPhone 15',
  imagenes: ['base64_1', 'base64_2', 'base64_3'], // Lista de imágenes
  // ...otros campos
);
```

#### **Widgets**
```dart
// ProductCard con múltiples imágenes
ProductCard(
  title: product.title,
  imageUrl: product.imageUrl,     // Imagen principal
  imagenes: product.imagenes,     // 🆕 Lista de imágenes
  // ...otros campos
)
```

## 📊 Flujo de Datos

### **Creación de Producto**
```
1. Usuario selecciona múltiples imágenes (máx 5)
2. Flutter convierte a base64
3. Se envían al backend como array de strings
4. Backend procesa cada imagen:
   - Extrae MIME type
   - Convierte base64 a buffer
   - Guarda en tabla imagenes_producto
5. Se retorna producto creado con URLs de imágenes
```

### **Visualización de Producto**
```
1. Frontend solicita productos (GET /api/products)
2. Backend incluye array de imágenes por producto
3. ProductCard detecta múltiples imágenes
4. Muestra carousel si > 1 imagen
5. Lazy loading de imágenes según demanda
```

## 🔧 Configuración de Desarrollo

### **Instalar Dependencias**
```bash
# Frontend
flutter pub get

# Backend
cd server
npm install
```

### **Variables de Entorno**
```env
# server/.env
MAX_IMAGES_PER_PRODUCT=5
IMAGE_MAX_SIZE_MB=10
IMAGE_QUALITY=70
```

## 🧪 Testing

### **Probar Múltiples Imágenes**

1. **Crear producto con 3 imágenes:**
```bash
curl -X POST http://localhost:3001/api/products \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "Test Product",
    "descripcion": "Producto de prueba",
    "precioActual": 50000,
    "categoriaId": 1,
    "imagenes": [
      "data:image/jpeg;base64,/9j/4AAQ...",
      "data:image/png;base64,iVBORw0K...",
      "data:image/jpeg;base64,/9j/4AAQ..."
    ]
  }'
```

2. **Verificar en la app:**
   - Abrir pantalla de inicio
   - Buscar el producto creado
   - Verificar que muestra indicador de múltiples imágenes
   - Deslizar para ver todas las imágenes

## 📈 Métricas de Rendimiento

### **Tamaños de Imagen Optimizados**
- **Calidad**: 70% (configurable)
- **Tamaño máximo**: 1024x1024px
- **Formatos soportados**: JPEG, PNG, WebP
- **Tamaño máximo por archivo**: 10MB

### **Optimizaciones**
- **Lazy loading** de imágenes en carousel
- **Cache** de imágenes con headers HTTP
- **Compresión automática** en cliente
- **Progressive loading** con indicadores

## 🛠️ Próximas Mejoras

### **Funcionalidades Pendientes**
- [ ] **Reordenamiento**: Drag & drop para cambiar orden de imágenes
- [ ] **Zoom**: Pellizcar para hacer zoom en imágenes
- [ ] **Galería completa**: Modal con vista completa de todas las imágenes
- [ ] **Edición**: Recortar/rotar imágenes antes de subir
- [ ] **Batch upload**: Subir múltiples productos con imágenes

### **Optimizaciones Técnicas**
- [ ] **WebP**: Conversión automática a formato WebP
- [ ] **CDN**: Integración con CDN para mejor rendimiento
- [ ] **Progressive images**: Carga progresiva de imágenes
- [ ] **Thumbnail generation**: Generación automática de miniaturas
- [ ] **Image recognition**: Detección automática de contenido inapropiado

## 🔍 Troubleshooting

### **Errores Comunes**

**Error: "Máximo 5 imágenes por producto"**
- Verificar que no se excedan las 5 imágenes
- Contar imágenes ya seleccionadas + nuevas imágenes

**Error: "Error procesando las imágenes"**
- Verificar formato de imagen (JPEG, PNG, WebP)
- Verificar tamaño de archivo (máx 10MB)
- Verificar conexión a internet

**Imágenes no se muestran en carousel**
- Verificar URLs de imágenes en respuesta del API
- Verificar que el campo `imagenes` no esté vacío
- Revisar logs de red para errores 404

### **Debug del Sistema**

**Verificar imágenes en base de datos:**
```sql
SELECT p.nombre, COUNT(ip.id) as num_imagenes 
FROM productos p 
LEFT JOIN imagenes_producto ip ON p.id = ip.producto_id 
GROUP BY p.id, p.nombre;
```

**Verificar tamaño de imágenes:**
```sql
SELECT 
  p.nombre,
  ip.mime_type,
  LENGTH(ip.imagen_data) as size_bytes
FROM productos p 
JOIN imagenes_producto ip ON p.id = ip.producto_id;
```

## 📞 Soporte

- **Documentación**: [README.md](./README.md)
- **API Docs**: [BACKEND_README.md](./BACKEND_README.md)
- **Issues**: Crear issue en repositorio con label `images`
