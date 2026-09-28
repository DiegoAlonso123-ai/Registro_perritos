# Registro de Perritos de la Calle

Aplicación web para registrar perritos encontrados en la calle: foto, nombre, raza, colores y ubicación en un mapa, para que rescatistas y vecinos sepan qué perros hay y dónde andan.

Funciona tanto en **computadora** como en **celular**. Desde el celular se puede tomar la foto directo con la cámara; desde la computadora, se sube un archivo de imagen ya existente (la cámara web no está soportada, solo la cámara trasera del celular vía `capture="environment"`). El resto de las funciones (mapa, lista, detalle, validaciones) funciona igual en ambos.

## Integrantes del equipo

| Nombre | Rol |
|---|---|
| Diego Orlando Alonso Alvarado | Backend y DBA |
| Jose Uriel Coronado Jaramillo | Frontend |
| Oscar Osvaldo Berlanga Sierra | DBA |

## Tecnologías y versiones exactas

- **Backend:** Node.js v20.20.1 + Express 4.19.2
- **Base de datos:** MySQL Community Server 8.0.45 (instalado directo en Windows, sin Docker)
- **Frontend:** HTML, CSS y JavaScript puro (sin frameworks) + Leaflet 1.9.4 (mapas, vía CDN, sin API key)
- **Otras librerías del backend:** mysql2 ^3.11.0, multer ^1.4.5-lts.1, file-type ^16.5.4, uuid ^9.0.1, cors ^2.8.5, dotenv ^16.4.5

> Este proyecto **no usa Docker**. Todo se instala directo en la máquina.

## Requisitos previos

- [Node.js](https://nodejs.org/) v18 o superior
- [MySQL Community Server](https://dev.mysql.com/downloads/mysql/) 8.0 o superior
- [MySQL Workbench](https://dev.mysql.com/downloads/workbench/) (opcional, para administrar la base visualmente)
- Un navegador moderno (Chrome, Edge, Firefox)
- La extensión **Live Server** de VS Code (o cualquier servidor estático local) para correr el frontend

## Instalación paso a paso

### 1. Clonar el repositorio

```bash
git clone https://github.com/TU-USUARIO/Registro_perritos.git
cd Registro_perritos
```

### 2. Crear la base de datos

Con MySQL Server corriendo, conéctate (por ejemplo con MySQL Workbench o la terminal `mysql`) y ejecuta los scripts en orden:

```bash
mysql -u root -p < database/schema.sql
mysql -u root -p < database/seed.sql
```

Esto crea la base `perritos_db`, sus 4 tablas, y carga los catálogos de razas y colores (12 razas, 12 colores).

> Si prefieres hacerlo visualmente: abre `database/schema.sql` en MySQL Workbench y ejecútalo completo (`Ctrl+Shift+Enter`), luego haz lo mismo con `database/seed.sql`.

### 3. Configurar el backend

```bash
cd backend
npm install
```

Crea un archivo `.env` (usa `.env.example` como base) con tus propios datos:


Crea la carpeta donde se guardarán las fotos (fuera del proyecto):

```bash
mkdir C:\perritos-imagenes
```

### 4. Correr el backend

```bash
npm run dev
```

Deberías ver:
Conectado a MySQL correctamente.
Servidor backend corriendo en http://localhost:3000


El backend queda disponible en **`http://localhost:3000`**.

### 5. Correr el frontend

Abre la carpeta `frontend/` en VS Code, clic derecho sobre `index.html` → **"Open with Live Server"** (o el botón "Go Live" abajo a la derecha).

**Importante:** no abras `index.html` con doble clic — el navegador bloquea la cámara y la ubicación si no se sirve por `http://localhost` o `https://`.

El frontend queda disponible en algo como **`http://127.0.0.1:5500`**.

## Configuración (variables de entorno)

| Variable | Ejemplo | Descripción |
|---|---|---|
| `DB_HOST` | `localhost` | Host de MySQL |
| `DB_PORT` | `3306` | Puerto de MySQL |
| `DB_USER` | `root` | Usuario de MySQL |
| `DB_PASSWORD` | *(tu contraseña)* | Contraseña de MySQL |
| `DB_NAME` | `perritos_db` | Nombre de la base de datos |
| `RUTA_IMAGENES` | `C:\perritos-imagenes` | Carpeta fuera del proyecto donde se guardan las fotos |
| `PORT` | `3000` | Puerto donde corre el backend |

Ver `backend/.env.example` para la plantilla completa (sin contraseñas reales).

## Probarlo desde un celular en la misma red

1. Encuentra la IP local de tu computadora: en PowerShell, `ipconfig` → busca "Dirección IPv4" (ej. `192.168.1.50`).
2. En `frontend/app.js`, cambia temporalmente la línea `const API_URL = "http://localhost:3000";` por `const API_URL = "http://192.168.1.50:3000";` (usa tu propia IP).
3. Abre el Firewall de Windows y permite conexiones entrantes al puerto 3000 (Panel de Control > Firewall de Windows Defender > Configuración avanzada > Regla de entrada nueva > Puerto > TCP 3000 > Permitir).
4. Asegúrate de que Live Server también sea accesible desde otros dispositivos de la red (en su configuración, revisa que no esté limitado a `127.0.0.1`).
5. Desde el celular (conectado al mismo WiFi), entra a `http://192.168.1.50:5500` (usa la IP y el puerto que te dé Live Server).
6. Prueba tomar una foto directo con la cámara del celular y registra un perrito.

## Endpoints de la API

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/api/razas` | Catálogo de razas |
| GET | `/api/colores` | Catálogo de colores |
| GET | `/api/perritos` | Lista todos los perritos (con JOIN a raza y color) |
| GET | `/api/perritos/:id` | Detalle de un perrito, con sus colores adicionales |
| POST | `/api/perritos` | Registrar un perrito nuevo (multipart/form-data, con foto) |
| GET | `/api/perritos/estadisticas/colores` | Cuántos perritos hay por color (agregación) |
| GET | `/api/imagenes/:nombre` | Sirve una imagen guardada (nunca se expone la carpeta directamente) |

## Capturas de pantalla

### Formulario de registro
![Formulario de registro](capturas/formulario.png)

### Mapa con los perritos registrados
![Mapa](capturas/mapa.png)

### Lista de perritos
![Lista](capturas/lista.png)

### Detalle de un perrito
![Detalle](capturas/detalle.png)

## Problemas comunes

- **"No se pudo conectar con el servidor" en el frontend** → verifica que el backend esté corriendo (`npm run dev` dentro de `backend/`) y que no haya errores en su terminal.
- **El backend no conecta a MySQL** → confirma que el servicio `MySQL80` esté corriendo (Windows: busca "Servicios" en el menú de inicio) y que la contraseña en `.env` sea la correcta.
- **La cámara o la ubicación no funcionan** → asegúrate de abrir el frontend con Live Server (`http://localhost:...`), nunca con doble clic al archivo.
- **"El archivo no es una imagen valida"** → el backend valida el contenido real del archivo, no solo su extensión; asegúrate de subir un JPG, PNG o WEBP real.
- **Puerto 3306 ocupado** → si tienes otro MySQL corriendo (por ejemplo, uno instalado junto con XAMPP), cambia `DB_PORT` en `.env` y en la configuración de tu servidor.

## Paradigmas usados en el proyecto

- **Declarativo (SQL):** todo el filtrado, ordenamiento y agregación de datos se resuelve en las consultas SQL, no en el código de la aplicación. Ejemplos en `backend/routes/perritos.js`:
  - La consulta de `GET /api/perritos` usa `JOIN` para combinar perritos con su raza y color, y `ORDER BY` para ordenarlos — el manejador de base de datos hace el trabajo, no un ciclo en JavaScript.
  - La consulta de `GET /api/perritos/estadisticas/colores` usa `GROUP BY` y `COUNT(*)` para la agregación (cuántos perritos hay por color).
  - HTML y CSS en el frontend también son declarativos: describen qué debe verse, no los pasos para dibujarlo.

- **Imperativo:** la lógica paso a paso de validación y control de flujo en el backend, por ejemplo el bloque de validaciones en `POST /api/perritos` (una serie de `if` que deciden qué responder), y el ciclo `for` que inserta cada color adicional uno por uno en la tabla intermedia.

- **Funcional:** en `backend/routes/perritos.js`, dentro de `GET /api/perritos/:id`, se transforma el resultado de la consulta de colores adicionales usando `map()`, sin mutar el arreglo original y sin ciclos explícitos:
```javascript
  const nombresColores = coloresAdicionales.map((fila) => fila.nombre);
```

- **Orientado a objetos:** el frontend usa la librería Leaflet, que expone objetos como `L.Marker` y `L.Map` con sus propios métodos (`.bindPopup()`, `.on()`, `.setLatLng()`) — se interactúa con el mapa manipulando instancias de esos objetos, no con funciones sueltas.

## Idempotencia del registro

**Problema que resuelve:** si el usuario presiona "Registrar" dos veces, o el celular reintenta la petición por mala señal, no debe crearse un perrito duplicado.

**Solución elegida:** una clave de idempotencia generada en el frontend (`idempotency_key`), usando `crypto.randomUUID()`, **al cargar el formulario** (no al enviarlo) — así, si el mismo formulario se envía más de una vez (por doble clic bloqueado a nivel de UI, o por un reintento de red), siempre viaja la misma clave.

En la base de datos, la columna `idempotency_key` de la tabla `perritos` tiene una restricción `UNIQUE`. El backend, antes de insertar, revisa si ya existe un perrito con esa clave:
- Si no existe, lo crea normalmente.
- Si ya existe, regresa el registro que ya estaba guardado (mismo `id`, mismos datos), con un campo extra `"duplicado_evitado": true`, **sin crear un registro nuevo**.

Esto se probó manualmente enviando la misma petición dos veces con Postman, confirmando que el `id` regresado es el mismo y que `SELECT COUNT(*) FROM perritos WHERE idempotency_key = '...'` da como resultado 1, no 2.