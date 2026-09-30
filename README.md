# Registro de Perritos de la Calle

Aplicación web para registrar perritos encontrados en la calle: foto, nombre, raza, colores y ubicación en un mapa, para que rescatistas, vecinos y asociaciones sepan qué perros hay, cómo identificarlos y en qué zona andan.

Funciona en **computadora** y en **celular**. Probado en un iPhone real (Safari): navegación, cámara y registro completo funcionan correctamente. El botón de ubicación automática solo funciona si el sitio se abre por `https://` (ver la sección de pruebas en celular); si no, se puede mover el pin a mano en el mapa, que también cumple el requisito.

## Integrantes del equipo

| Nombre | Rol |
|---|---|
| Diego Orlando Alonso Alvarado | Backend y DBA |
| Jose Uriel Coronado Jaramillo | Frontend |
| Oscar Osvaldo Berlanga Sierra | DBA |

## Qué hace la aplicación

- **Registrar** un perrito: foto (cámara o archivo JPG/PNG/WEBP), nombre, raza (opcional, de catálogo), color principal (obligatorio, de catálogo), 0 a 2 colores adicionales y ubicación (pin en el mapa: ubicación actual o movido a mano). La fecha la pone el sistema.
- **Mapa** con un pin por perrito; al tocarlo se ve su foto, nombre, raza y color.
- **Lista** de perritos con foto en miniatura.
- **Detalle** de cada perrito (al tocar su tarjeta).
- **Validaciones** en el frontend y en el backend, con mensajes entendibles (por ejemplo "Falta la foto").
- **Aviso de registro:** al guardar, un cuadro confirma "¡Perrito registrado!". Si el backend detecta que ese envío ya se había guardado, el cuadro dice "Este perrito ya estaba registrado". Si eliges la misma foto que ya registraste en la sesión, la app pide confirmación antes de enviar.

## Tecnologías, versiones y dónde descargarlas

| Tecnología | Versión usada | Descarga |
|---|---|---|
| Node.js | v20.20.1 (v18+ funciona) | https://nodejs.org/ |
| MySQL Community Server | 8.0.45 | https://dev.mysql.com/downloads/mysql/ |
| MySQL Workbench (opcional, GUI) | — | https://dev.mysql.com/downloads/workbench/ |
| Visual Studio Code | — | https://code.visualstudio.com/ |
| Extensión Live Server (para VS Code) | — | https://marketplace.visualstudio.com/items?itemName=ritwickdey.LiveServer |
| Git | — | https://git-scm.com/downloads |
| Express | 4.19.2 | (se instala con `npm install`) |
| Leaflet (mapas, vía CDN) | 1.9.4 | (no requiere instalación, se carga por internet) |
| cloudflared (opcional, para probar en celular con HTTPS) | — | https://github.com/cloudflare/cloudflared/releases/latest |

**Librerías del backend** (se instalan solas con `npm install`, no hay que descargarlas aparte): mysql2 ^3.11.0, multer ^1.4.5-lts.1, file-type ^16.5.4, cors ^2.8.5, dotenv ^16.4.5, nodemon ^3.1.4 (desarrollo).

> Este proyecto **no usa Docker**. Todo se instala directo en la máquina.

## Instalación paso a paso

Los comandos vienen para **Windows (PowerShell)** y **Mac (Terminal)**. Sigue solo la columna de tu sistema.

### 1. Instalar los requisitos

| Windows | Mac |
|---|---|
| Instala Node.js desde https://nodejs.org/ (botón LTS) | Instala Node.js desde https://nodejs.org/, o con Homebrew: `brew install node` |
| Instala MySQL Server desde https://dev.mysql.com/downloads/mysql/ (elige "MySQL Installer for Windows") | Instala MySQL con Homebrew: `brew install mysql` |
| Instala MySQL Workbench (opcional) desde https://dev.mysql.com/downloads/workbench/ | Instala MySQL Workbench desde el mismo link, o `brew install --cask mysqlworkbench` |
| Instala VS Code desde https://code.visualstudio.com/ | Igual, desde el mismo link |
| Instala Git desde https://git-scm.com/downloads (o ya viene con Windows si tienes GitHub Desktop) | Git ya viene instalado en Mac; si no, `brew install git` |

En VS Code, instala la extensión **Live Server**: ícono de Extensiones (los cuadritos, a la izquierda) > busca "Live Server" (de Ritwick Dey) > Install. Es igual en Windows y Mac.

**Inicia MySQL:**
- Windows: se inicia solo como servicio (revisa en "Servicios" que `MySQL80` esté "Running").
- Mac: `brew services start mysql`

### 2. Clonar el repositorio

```bash
git clone https://github.com/DiegoAlonso123-ai/Registro_perritos.git
cd Registro_perritos
```

### 3. Crear la base de datos

**Windows (PowerShell):**
```powershell
cmd /c "mysql -u root -p < database\schema.sql"
cmd /c "mysql -u root -p < database\seed.sql"
cmd /c "mysql -u root -p < database\seed-perritos.sql"
```

**Mac (Terminal):**
```bash
mysql -u root -p < database/schema.sql
mysql -u root -p < database/seed.sql
mysql -u root -p < database/seed-perritos.sql
```

Cada comando pide la contraseña de `root` de MySQL. Esto crea la base `perritos_db` con sus 4 tablas, carga los catálogos (12 razas y 12 colores) y 15 perritos de prueba. El último script (`seed-perritos.sql`) es opcional: solo carga datos de ejemplo.

> Alternativa visual: en MySQL Workbench abre cada archivo (`database/schema.sql`, `database/seed.sql`, `database/seed-perritos.sql`) y ejecútalo completo con `Ctrl+Shift+Enter` (o `Cmd+Shift+Enter` en Mac), en ese orden.

El diagrama entidad-relación está en `database/diagrama-entidad-relacion.png`.

### 4. Crear la carpeta de imágenes (fuera del proyecto)

Las fotos **no** se guardan dentro del repositorio; van en un directorio externo definido por `RUTA_IMAGENES`.

**Windows:**
```powershell
mkdir C:\perritos-imagenes
copy database\fotos-prueba\* C:\perritos-imagenes\
```

**Mac:**
```bash
mkdir -p ~/perritos-imagenes
cp database/fotos-prueba/* ~/perritos-imagenes/
```

Las fotos de `database/fotos-prueba/` son las de los 15 perritos de prueba. Si no cargaste `seed-perritos.sql`, puedes omitir el paso de copiar.

### 5. Configurar el backend

```bash
cd backend
npm install
```

Copia `backend/.env.example` a `backend/.env` y ajusta tus valores.

**Windows** (`backend/.env`):
```
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=tu_contraseña_de_mysql
DB_NAME=perritos_db

RUTA_IMAGENES=C:\perritos-imagenes

PORT=3000
```

**Mac** (`backend/.env`):
```
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=tu_contraseña_de_mysql
DB_NAME=perritos_db

RUTA_IMAGENES=/Users/tu-usuario/perritos-imagenes

PORT=3000
```

### 6. Correr el backend

```bash
npm run dev
```

Debes ver:

```
Conectado a MySQL correctamente.
Servidor backend corriendo en http://localhost:3000
```

### 7. Correr el frontend

Abre la carpeta del proyecto en VS Code, clic derecho sobre `frontend/index.html` y elige **Open with Live Server** (o el botón "Go Live" de abajo a la derecha). Queda en algo como **http://127.0.0.1:5500/frontend/index.html**. Es igual en Windows y Mac.

> No abras `index.html` con doble clic: el navegador bloquea la cámara y la ubicación fuera de `http://localhost` o `https://`.

## Configuración (variables de entorno)

| Variable | Ejemplo | Descripción |
|---|---|---|
| `DB_HOST` | `localhost` | Host de MySQL |
| `DB_PORT` | `3306` | Puerto de MySQL |
| `DB_USER` | `root` | Usuario de MySQL |
| `DB_PASSWORD` | `tu_contraseña_de_mysql` | Contraseña de MySQL (nunca se sube a Git) |
| `DB_NAME` | `perritos_db` | Nombre de la base de datos |
| `RUTA_IMAGENES` | `C:\perritos-imagenes` / `/Users/tu-usuario/perritos-imagenes` | Carpeta fuera del proyecto donde se guardan las fotos |
| `PORT` | `3000` | Puerto del backend |

El archivo `.env` está en `.gitignore`. La plantilla sin contraseñas es `backend/.env.example`.

En el frontend, la URL del backend está en `frontend/app.js` (`API_URL`). Por defecto usa `` `http://${location.hostname}:3000` ``, que funciona tanto en la computadora como en el celular en la misma red, sin tener que cambiarla a mano.

## Almacenamiento de imágenes

- Las fotos se guardan en disco, en la ruta `RUTA_IMAGENES`, **fuera** de cualquier carpeta del código o de despliegue.
- El backend **genera el nombre** del archivo (un UUID); nunca usa el nombre que mandó el usuario.
- El backend **valida el contenido real** del archivo (lee sus bytes con `file-type`), no solo la extensión. Solo acepta JPG, PNG y WEBP.
- Las imágenes se sirven por el endpoint `GET /api/imagenes/:nombre`; la carpeta nunca se expone directamente. El endpoint también protege contra rutas del tipo `../`.
- `database/fotos-prueba/` en el repositorio es solo material de instalación; el backend nunca la sirve ni la usa directamente.

## Probarlo desde un celular (Recomendada la opcion A)

Hay dos formas. La primera es más simple pero con una limitación; la segunda (con HTTPS) funciona completo, incluida la ubicación automática por GPS.

### Opción A: en la misma red WiFi (rápida, sin ubicación automática)

**1.** Abre el Firewall de Windows y permite los puertos 3000 y 5500 (en Mac normalmente no hace falta, macOS pregunta la primera vez y basta con aceptar):

- Busca "Firewall de Windows Defender con seguridad avanzada" en el menú de inicio.
- Panel izquierdo: "Reglas de entrada" > panel derecho: "Nueva regla...".
- Tipo: **Puerto** > Siguiente.
- **TCP**, puertos locales específicos: `3000,5500` > Siguiente.
- **Permitir la conexión** > Siguiente.
- Deja marcados Dominio, Privado y Público > Siguiente.
- Nombre: "Perritos backend y frontend" > Finalizar.

**2.** Averigua la IP de tu computadora:
- Windows: `ipconfig`, busca "Dirección IPv4".
- Mac: `ipconfig getifaddr en0` (o revisa Preferencias del Sistema > Red).

**3.** Con el celular en el mismo WiFi, abre `http://tu-ip:5500/frontend/index.html`.

**Limitación confirmada:** por ser una conexión `http://` (no `https://`), el navegador del celular bloquea el botón "Usar mi ubicación actual" con el error "origin does not have permission to use geolocation service". Es una restricción normal de seguridad del navegador, no un error de la app. El registro funciona igual moviendo el pin a mano en el mapa, que también cumple el requisito del proyecto.

### Opción B: con HTTPS real, usando un túnel (ubicación automática incluida)

Usamos **Cloudflare Tunnel** (`cloudflared`), gratis y sin necesidad de cuenta.

**1.** Descarga `cloudflared`:
- Windows: desde https://github.com/cloudflare/cloudflared/releases/latest descarga `cloudflared-windows-amd64.exe`, ponlo en una carpeta como `C:\cloudflared` y renómbralo a `cloudflared.exe`.
- Mac: `brew install cloudflared`

**2.** Ten corriendo el backend (`npm run dev` en `backend`) y el frontend con Live Server.

**3.** Abre una terminal nueva y crea el túnel del backend:

Windows:
```powershell
cd C:\cloudflared
.\cloudflared.exe tunnel --url http://localhost:3000
```

Mac:
```bash
cloudflared tunnel --url http://localhost:3000
```

Copia la URL `https://algo.trycloudflare.com` que te da. Esa es tu **backend público**.

**4.** Abre otra terminal (sin cerrar la anterior) y crea el túnel del frontend:

Windows:
```powershell
cd C:\cloudflared
.\cloudflared.exe tunnel --url http://localhost:5500
```

Mac:
```bash
cloudflared tunnel --url http://localhost:5500
```

Copia esta otra URL. Es tu **frontend público**.

**5.** En `frontend/app.js`, cambia temporalmente la línea de `API_URL` por la URL del backend del paso 3:

```javascript
const API_URL = "https://la-url-del-backend.trycloudflare.com";
```

**6.** En el celular (puede ser con datos móviles, no hace falta la misma WiFi), abre la URL del frontend agregando `/frontend/index.html` al final, por ejemplo:

```
https://la-url-del-frontend.trycloudflare.com/frontend/index.html
```

Ahora el botón "Usar mi ubicación actual" pide permiso real y funciona.

**Importante:** las URLs de `trycloudflare.com` cambian cada vez que cierras y vuelves a abrir el túnel. Hay que repetir los pasos 3 a 6 cada vez que se quiera usar (incluido el día de la demo). Al terminar de probar, regresa `API_URL` en `frontend/app.js` a:

```javascript
const API_URL = `http://${location.hostname}:3000`;
```

antes de hacer commit, para no romper el uso normal en local.

## Endpoints de la API

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/api/razas` | Catálogo de razas |
| GET | `/api/colores` | Catálogo de colores |
| GET | `/api/perritos` | Lista de perritos (con `JOIN` a raza y color) |
| GET | `/api/perritos/:id` | Detalle de un perrito, con sus colores adicionales |
| POST | `/api/perritos` | Registra un perrito (`multipart/form-data`, con foto) |
| GET | `/api/perritos/estadisticas/colores` | Cuántos perritos hay por color (agregación) |
| GET | `/api/imagenes/:nombre` | Sirve una imagen guardada |

### Campos de `POST /api/perritos`

| Campo | Obligatorio | Regla |
|---|---|---|
| `foto` | Sí | Archivo JPG, PNG o WEBP (máx. 8 MB) |
| `nombre` | Sí | Texto no vacío; solo espacios no cuenta |
| `raza_id` | No | Id del catálogo de razas |
| `color_principal_id` | Sí | Id del catálogo de colores |
| `colores_adicionales` | No | Arreglo JSON de ids, por ejemplo `[2,5]`. Máximo 2, sin repetir entre sí ni repetir el principal |
| `ubicacion_lat`, `ubicacion_lng` | Sí | Coordenadas del pin |
| `idempotency_key` | Sí | Clave única del envío (ver sección de idempotencia) |

Respuestas de error en JSON con mensaje entendible, por ejemplo `{ "error": "Falta la foto" }`. La fecha de registro la pone el sistema.

## Capturas de pantalla

### Formulario de registro
![Formulario de registro](capturas/formulario.png)

### Mapa con los perritos registrados
![Mapa](capturas/mapa.png)

### Lista de perritos
![Lista](capturas/lista.png)

### Detalle de un perrito
![Detalle](capturas/detalle.png)

## Estructura del repositorio

```
Registro_perritos/
├── backend/
│   ├── server.js            # arranque de la API y endpoint de imágenes
│   ├── db.js                # conexión a MySQL
│   ├── imagenes.js          # guardado y validación de fotos
│   ├── pruebas/
│   │   └── doble-envio.js   # prueba automática de idempotencia
│   ├── routes/
│   │   ├── perritos.js      # registro, lista, detalle, estadística
│   │   └── catalogos.js     # razas y colores
│   ├── .env.example
│   └── package.json
├── database/
│   ├── schema.sql            # creación de tablas
│   ├── seed.sql               # catálogos de razas y colores
│   ├── seed-perritos.sql     # 15 perritos de prueba
│   ├── fotos-prueba/          # fotos de los perritos de prueba
│   ├── respaldo.ps1           # respaldo de base + imágenes
│   ├── restaurar.ps1          # restauración de base + imágenes
│   └── diagrama-entidad-relacion.png
├── frontend/
│   ├── index.html
│   ├── style.css
│   └── app.js
├── capturas/                  # imágenes usadas en este README
└── README.md
```

## Flujo de trabajo con Git

- Un solo repositorio para el equipo.
- Se trabaja en ramas (`feature/...`, `docs/...`) y se fusiona a `main` mediante pull request revisado por otro integrante.
- Los mensajes de commit describen qué cambió.
- No se suben contraseñas (`.env`), `node_modules/`, fotos pesadas ni respaldos (`respaldos/`); para eso está el `.gitignore`.

## Respaldo y restauración

Desde la raíz del repositorio, en PowerShell (Windows):

```powershell
.\database\respaldo.ps1
```

Crea una carpeta `respaldos\<fecha_hora>\` con `perritos_db.sql` (la base completa) y `imagenes\` (copia de `RUTA_IMAGENES`). Pide la contraseña de MySQL. Los respaldos están en `.gitignore`.

Para restaurar:

```powershell
.\database\restaurar.ps1 -Carpeta respaldos\2026-09-27_23-42
```

Reemplaza la base `perritos_db` por la del respaldo y copia las imágenes de vuelta a `RUTA_IMAGENES`. Si Windows bloquea los scripts, ejecuta una vez `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

## Problemas comunes

- **"No se pudo conectar con el servidor" en el frontend:** verifica que el backend esté corriendo y que `API_URL` en `frontend/app.js` apunte a él.
- **El backend no conecta a MySQL:** confirma que MySQL esté corriendo (Windows: servicio `MySQL80`; Mac: `brew services list`) y que la contraseña en `.env` sea correcta.
- **Las razas y colores no cargan en el formulario:** falta correr `database/seed.sql`, o el backend no está corriendo.
- **Error "No database selected" al correr un script:** el script no trae la línea `USE perritos_db;` al inicio.
- **En el celular no navega nada (pestañas, selects, mapa) aunque en la compu sí funciona:** `crypto.randomUUID()` requiere un contexto seguro (`https://` o `localhost`); al entrar por IP con `http://` esa línea fallaba y detenía el script. Ya está resuelto con una función alterna (`generarUUID()`) que funciona con o sin contexto seguro.
- **El botón "Usar mi ubicación actual" no pide permiso en el celular:** normal si se prueba por `http://` (ver "Probarlo desde un celular", Opción A vs B).
- **"El archivo no es una imagen valida":** el backend revisa el contenido real del archivo; sube un JPG, PNG o WEBP verdadero.
- **Error `ERR_PACKAGE_PATH_NOT_EXPORTED` con `file-type`:** se necesita la versión 16 (`"file-type": "^16.5.4"`); las versiones nuevas son solo ESM y no funcionan con `require`.
- **Puerto 3306 ocupado:** si hay otro MySQL corriendo, cambia `DB_PORT` en `.env`.
- **PowerShell no deja correr `respaldo.ps1` / `restaurar.ps1`:** ejecuta una vez `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.
- **Las fotos no se ven:** revisa que `RUTA_IMAGENES` exista y tenga los archivos que la base referencia.

## Paradigmas usados en el proyecto

**Declarativo (SQL, HTML y CSS).** El filtrado, ordenamiento y agregación de datos se resuelven en SQL; el manejador de base de datos decide cómo ejecutarlos. En `backend/routes/perritos.js`:
- `GET /api/perritos` usa `JOIN` entre perritos, razas y colores, y `ORDER BY` para ordenar.
- `GET /api/perritos/estadisticas/colores` usa `JOIN`, `GROUP BY` y `COUNT(*)` para contar perritos por color.
- HTML y CSS también son declarativos: describen qué debe verse, no cómo dibujarlo.

**Imperativo.** Paso a paso, en `POST /api/perritos`: la cadena de validaciones con `if` y el ciclo `for` que inserta cada color adicional. En el frontend, el manejador del formulario en `app.js` valida, arma el `FormData`, envía y actualiza la interfaz.

**Funcional.** En `GET /api/perritos/:id` (`backend/routes/perritos.js`), las filas de colores adicionales se transforman con `map()`, sin mutar el resultado original y sin ciclos explícitos:

```javascript
const nombresColores = coloresAdicionales.map((fila) => fila.nombre);
```

En el frontend, `Array.from(...selectedOptions).map(...)` en `app.js` convierte las opciones elegidas en una lista de ids con el mismo estilo.

**Orientado a objetos.** El frontend usa Leaflet, que trabaja con instancias de objetos (`L.Map`, `L.Marker`) y sus métodos (`.bindPopup()`, `.on()`, `.setLatLng()`); el mapa se controla manipulando esos objetos.

## Idempotencia del registro

**Problema:** si el usuario presiona "Registrar" dos veces, o el celular reintenta la petición por mala señal, no debe quedar un perrito duplicado.

**Solución elegida:** una **clave de idempotencia por formulario**.
- El frontend genera `idempotency_key` al cargar la página y la reutiliza en cada intento de envío. Solo genera una nueva después de un registro exitoso, para el siguiente perrito. Se usa una función propia (`generarUUID()`) compatible con y sin contexto seguro, en vez de depender solo de `crypto.randomUUID()`.
- En la base, `perritos.idempotency_key` es `UNIQUE`.
- Antes de insertar, el backend busca esa clave. Si ya existe, **no crea nada nuevo**: responde con el registro original (mismo `id`, mismos datos) y `"duplicado_evitado": true`.

**Por qué esta clave y no una natural:** nombre, foto o ubicación no identifican a un perrito de forma única (puede haber dos perros con el mismo nombre o en el mismo lugar), mientras que la clave por formulario identifica exactamente un intento de registro.

**Capas de protección en el frontend:** el botón "Registrar" se deshabilita mientras se envía; si la respuesta trae `duplicado_evitado`, se avisa "Este perrito ya estaba registrado"; y si se elige la misma foto que ya se registró en la sesión, se pide confirmación (aviso, no bloqueo, porque podrían ser perros distintos).

**Prueba manual (con Postman):**
1. Envía `POST /api/perritos` (form-data) con `idempotency_key = demo-vivo` y todos los campos, incluida una foto.
2. Anota el `id` de la respuesta (201).
3. Envía **exactamente la misma petición** otra vez: responde con el **mismo `id`** y `duplicado_evitado: true`.
4. Verifica en la base: `SELECT COUNT(*) FROM perritos WHERE idempotency_key = 'demo-vivo';` da como resultado 1.

**Prueba automática:** con el backend corriendo, desde la carpeta `backend`:

```powershell
npm run prueba:doble-envio
```

Envía dos veces el mismo registro (con la misma `idempotency_key`) y verifica que el segundo envío devuelve el mismo `id`, indica `duplicado_evitado` y no crea otro registro. Deja un perrito de prueba en la base; se borra con:

```sql
DELETE FROM perritos WHERE idempotency_key LIKE 'prueba-doble-envio-%' AND id > 0;
```

## Despliegue (punto extra)

**Dónde correría cada pieza:** el backend (Node/Express) en un servicio con proceso administrado (ver abajo); MySQL en el mismo servidor o en un servicio administrado aparte; las imágenes en un directorio del servidor fuera del código (mismo principio que en local, por ejemplo `/var/perritos-imagenes`), nunca junto al código ni en carpetas públicas.

**Dominio y HTTPS:** para una demo rápida usamos un túnel de Cloudflare (`cloudflared tunnel --url ...`), que da un dominio `.trycloudflare.com` con HTTPS automático, sin configurar nada de certificados. Para un dominio propio y permanente, se registraría un dominio y se usaría Cloudflare o Let's Encrypt (con Certbot) para el certificado.

**Diferencias entre local y producción:** en producción, `DB_HOST` ya no sería `localhost` sino la dirección del servidor de base de datos; `RUTA_IMAGENES` apuntaría a un disco del servidor con espacio suficiente; las contraseñas (`DB_PASSWORD`) se guardarían como variables de entorno del servicio, nunca en un archivo subido al repositorio.

**Puertos expuestos:** solo el puerto del backend (o el del proxy inverso que lo sirva) quedaría abierto hacia internet. El puerto de MySQL (3306) nunca se expone directamente.

**Respaldo en producción:** el mismo principio de `database/respaldo.ps1`, pero programado (por ejemplo con una tarea programada o un cron job) para correr automáticamente, guardando los respaldos fuera del propio servidor (por ejemplo, en un almacenamiento en la nube aparte).

**Cómo se logró para la demo:** usamos Cloudflare Tunnel para exponer temporalmente el backend y el frontend que corren en la computadora, sin instalar nada en un servidor. Es la opción más simple para una demostración en vivo, aunque no es una instalación permanente: sin Docker (como pide el proyecto) para un despliegue real y duradero, la instalación sería directa en un servidor (por ejemplo, una VPS), con el servicio de Node administrado por `systemd` para que se reinicie solo si falla, y un proxy inverso como **nginx** o **Caddy** al frente, que además se encargaría del certificado HTTPS de forma automática.