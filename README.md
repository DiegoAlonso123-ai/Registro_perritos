# Perritos de la calle — Proyecto 2 (Elixir)

Aplicación para registrar perritos de la calle: foto, nombre, raza, colores y ubicación en un mapa. Esta es la **segunda versión**: la app del Proyecto 1 creció, en el mismo repositorio, con tres funcionalidades nuevas escritas en **Elixir** con estilo funcional. Ahora se levanta completa con **Docker** y se publica en internet con un **túnel de Cloudflare**.

- Repositorio: https://github.com/DiegoAlonso123-ai/Registro_perritos
- URL pública durante la demostración: La URL cambia cada que se levanta en docker 
  (la URL cambia cada vez que se reinicia el túnel; ver la sección 3.5)

## Contenido

1. [Integrantes y funcionalidades](#1-integrantes-y-funcionalidades)
2. [Del P1 al P2](#2-del-p1-al-p2)
3. [Cómo levantarla con Docker](#3-cómo-levantarla-con-docker)
4. [Arquitectura](#4-arquitectura)
5. [Las funcionalidades en Elixir](#5-las-funcionalidades-en-elixir)
6. [Pruebas](#6-pruebas)
7. [Trabajo en equipo con Git](#7-trabajo-en-equipo-con-git)
8. [Problemas comunes](#8-problemas-comunes)
9. [Estructura del repositorio](#9-estructura-del-repositorio)

## 1. Integrantes y funcionalidades

| Integrante | Rol en el P1 | Funcionalidad del P2 |
|---|---|---|---|
| Diego Orlando Alonso Alvarado | Backend y DBA |Estadisticas y la infraestructura (Docker, proxy, túnel, servicio Elixir base, endpoint `/api/avistamientos`) |  funcionalidad, infraestructura |
| Jose Uriel Coronado Jaramillo | Frontend | #4 Zonas de concentración |
| Oscar Osvaldo Berlanga Sierra | DBA | Perdidos |

Las funcionalidades del catálogo del proyecto que se hicieron son **#3 Estadísticas**, **#7 Perros perdidos de vista** y **#4 Zonas de concentración**.

## 2. Del P1 al P2

### 2.1 Qué había al terminar el P1

- **Frontend** en HTML, CSS y JavaScript puro, con Leaflet: formulario con foto (cámara o archivo), mapa con pin, lista y detalle.
- **Backend** en Node.js 20 + Express: API REST (`/api/razas`, `/api/colores`, `/api/perritos`, `/api/imagenes/:nombre`), validaciones del lado del servidor, fotos guardadas fuera del código y validadas por su contenido, y registro idempotente con `idempotency_key`.
- **Base de datos** MySQL 8.0 con 4 tablas, catálogos de 12 razas y 12 colores y 15 perritos de prueba.
- Se ejecutaba **sin Docker**: Node y MySQL instalados en la máquina y el frontend con Live Server.

### 2.2 Qué se agregó en el P2

- Un **servicio Elixir** (`funcional/`) con Plug, Bandit, Jason y Req, dividido en **núcleo puro** y **cáscara** (sección 4.3).
- **Tres funcionalidades** nuevas (sección 5), cada una con su pestaña en el frontend.
- Un **proxy nginx** como única entrada y un **túnel de Cloudflare** que lo publica en internet.
- **Docker** para todo: `docker-compose.yml` y un `Dockerfile` por servicio (el de Elixir en dos etapas, con `mix release`).
- El endpoint `GET /api/avistamientos` en el backend, para que Elixir lea los datos.
- **Datos de muestra**: más de 100 avistamientos (115 en la base de muestra) con sus fotos, cargados por scripts versionados.

### 2.3 Qué se modificó del código del P1

| Archivo | Cambio | Por qué |
|---|---|---|
| `backend/routes/avistamientos.js` (nuevo) y `backend/server.js` | Endpoint nuevo `GET /api/avistamientos`, con un `JOIN` y `GROUP_CONCAT` en SQL | El servicio Elixir necesita todos los colores, la latitud, la longitud y la fecha de cada avistamiento; `/api/perritos` solo trae el color principal |
| `frontend/app.js` | `API_URL` pasó de `http://<host>:3000` a rutas relativas (con Live Server en el puerto 5500 se sigue usando el backend directo) | Todo entra por el proxy, y en el celular de un visitante `localhost` es su propio celular |
| `frontend/index.html` | Tres pestañas nuevas, con sus `<link>` y `<script>` | Las funcionalidades se usan desde la app |
| `frontend/estadisticas.css` | La barra de pestañas se desliza de lado | Con 6 pestañas ya no caben en un celular |
| `database/seed-perritos.sql` y `database/fotos-prueba/` | De 15 a más de 100 avistamientos | Datos de muestra suficientes |
| `docker-compose.yml`, `.env.example`, `proxy/nginx.conf`, `backend/Dockerfile`, `frontend/Dockerfile` y sus `.dockerignore` | Nuevos | Docker, proxy y túnel |
| `README.md` | Reescrito | Describe el P2 |

## 3. Cómo levantarla con Docker

### 3.1 Requisitos

Solo dos programas. **No** hace falta instalar Node, Elixir ni MySQL.

- **Docker Desktop** (Windows o Mac): https://www.docker.com/products/docker-desktop/ . En Linux, Docker Engine con el complemento Compose. En Windows, Docker Desktop necesita la virtualización activada.
- **Git**: https://git-scm.com/downloads

Comprueba que funcionan (con Docker Desktop abierto, esperando a que diga "Engine running"):

```bash
docker --version
docker compose version
git --version
```

### 3.2 Paso a paso, desde un clon limpio

**1. Clonar el repositorio**

```bash
git clone https://github.com/DiegoAlonso123-ai/Registro_perritos.git
cd Registro_perritos
```

**2. Crear el archivo de configuración `.env`**

Windows (PowerShell):

```powershell
Copy-Item .env.example .env
```

Mac o Linux:

```bash
cp .env.example .env
```

Abre `.env` y cambia `cambiar` por una contraseña sencilla, sin símbolos raros:

```
MYSQL_ROOT_PASSWORD=mi_contrasena
```

El archivo `.env` no se sube a Git. El que sí se sube es `.env.example`, sin contraseñas reales.

**3. Levantar todo**

```bash
docker compose up --build
```

La primera vez tarda varios minutos: construye las imágenes (Elixir compila sus dependencias) y MySQL crea la base y corre sus scripts. La app está lista cuando en la terminal aparecen estas dos líneas:

```
backend-1   | Servidor backend corriendo en http://localhost:3000
funcional-1 | Running Perritos.Router with Bandit ... at 0.0.0.0:4000 (http)
```

**4. Abrir la app en local**

Abre **http://localhost:8080** en el navegador. Debe verse el formulario, y en las pestañas Mapa y Lista deben aparecer los perritos de muestra con su foto. Para comprobar el servicio Elixir, en otra terminal:

```bash
curl http://localhost:8080/f/salud
```

Debe contestar `ok` (en PowerShell usa `curl.exe`).

**5. Obtener la URL pública (túnel de Cloudflare)**

```powershell
docker compose logs tunel | Select-String trycloudflare
```

En Mac o Linux:

```bash
docker compose logs tunel | grep trycloudflare
```

Aparece una dirección como `https://algo-aleatorio.trycloudflare.com`. Esa es la URL pública, con `https`, y se puede abrir desde cualquier celular con datos móviles. Si hay varias líneas, la vigente es la **última**.

**6. Detener**

Presiona `Ctrl+C` **una sola vez** en la terminal del `docker compose up` y espera. Luego:

```bash
docker compose down
```

Esto apaga los contenedores **sin borrar** los datos. **No uses `docker compose down -v` a menos que quieras borrar la base y las fotos**: eso las vuelve a crear desde los scripts, y se pierde lo que se haya registrado desde la app.

### 3.3 Qué hace `docker compose up` con los datos

- **Base de datos:** MySQL ejecuta, **solo la primera vez** (cuando su volumen está vacío), los tres scripts de `database/`, en orden: `schema.sql` (tablas), `seed.sql` (catálogos de razas y colores) y `seed-perritos.sql` (más de 100 avistamientos de muestra).
- **Fotos:** al arrancar, el backend copia las fotos de `database/fotos-prueba/` al volumen `imagenes` (sin pisar las que ya existan). Las fotos viven **fuera de las carpetas de la aplicación**, en ese volumen, y solo se sirven por `GET /api/imagenes/:nombre`.

Para comprobar cuántos avistamientos hay:

```bash
curl -s http://localhost:8080/api/avistamientos
```

(Debe traer más de 100 elementos.)

### 3.4 Volver a empezar de cero

```bash
docker compose down -v
docker compose up --build
```

Esto borra los volúmenes (base y fotos) y los crea de nuevo con los datos de muestra.

### 3.5 La URL del túnel cambia

Este túnel rápido de Cloudflare no necesita cuenta, pero **la URL cambia cada vez que el contenedor `tunel` se vuelve a crear** (al hacer `down`, al reiniciar Docker o la computadora). Por eso el día de la demostración se levanta antes de la clase, se obtiene la URL con el comando del paso 5, se prueba desde un celular con datos móviles y se escribe al inicio de este README.

## 4. Arquitectura

```
visitante ──▶ https://….trycloudflare.com
                         │
                         ▼
                 túnel (cloudflared)
                         │
                         ▼
                 proxy (nginx) :80  ──── publicado como localhost:8080
        ┌────────────────┼──────────────────┐
        │ /              │ /api/            │ /f/
        ▼                ▼                  ▼
  frontend (nginx)   backend (Node)    funcional (Elixir)
  HTML, CSS y JS     API REST del P1   ┌────────────────────────┐
                           │           │ CÁSCARA: rutas HTTP,    │
                           │           │ lectura de datos, JSON  │
                           │           │ ┌────────────────────┐  │
                           │           │ │ NÚCLEO PURO        │  │
                           │           │ │ datos entran,      │  │
                           │           │ │ datos salen        │  │
                           │           │ └────────────────────┘  │
                           │           └───────────┬────────────┘
                           ▼                       │ GET /api/avistamientos
                    base de datos (MySQL) ◀────────┘ (pasa por el backend)
```

### 4.1 Los contenedores

Son **6** (más `herramientas`, que solo se usa a demanda para correr `mix` y no arranca con `docker compose up`).

| Servicio | Imagen | Qué hace |
|---|---|---|
| `db` | `mysql:8.0` | Base de datos del P1; ejecuta los scripts de `database/` la primera vez |
| `backend` | `node:20-alpine` | API REST del P1 y endpoint `/api/avistamientos` |
| `funcional` | `elixir:1.18-alpine` (release en dos etapas) | Las tres funcionalidades nuevas, en Elixir |
| `frontend` | `nginx:1.27-alpine` | Sirve el HTML, CSS y JS |
| `proxy` | `nginx:1.27-alpine` | Única entrada: reparte las peticiones por ruta |
| `tunel` | `cloudflare/cloudflared` | Publica el proxy en internet con `https` |

Solo el `proxy` publica un puerto (8080). La base de datos **no** se expone.

### 4.2 Cómo reparte el proxy (`proxy/nginx.conf`)

| Ruta | Va a | Nota |
|---|---|---|
| `/api/...` | `backend:3000` | Conserva el prefijo `/api`, porque las rutas del backend ya lo llevan |
| `/f/...` | `funcional:4000` | Conserva el prefijo `/f`; así se escriben las rutas del router de Elixir |
| `/` | `frontend:80` | El resto, la interfaz |

El frontend llama a todo con **rutas relativas** (`/api/...`, `/f/...`), nunca con `localhost`.

### 4.3 Núcleo y cáscara en Elixir

| Parte | Archivos en `funcional/lib/perritos/` | Qué hace |
|---|---|---|
| **Núcleo** (funciones puras) | `estadisticas.ex`, `perdidos.ex`, `zonas.ex`, `avistamiento.ex` (solo el struct) | Reciben listas, mapas y structs y regresan listas, mapas y structs. No consultan la base de datos, no reciben peticiones, no leen el reloj, no imprimen |
| **Cáscara** (efectos) | `application.ex`, `router.ex`, `estadisticas_router.ex`, `perdidos_router.ex`, `zonas_router.ex`, `datos.ex` | Reciben la petición HTTP, traen los avistamientos, leen el reloj (en Perdidos), llaman al núcleo y responden JSON |

### 4.4 Cómo obtiene los datos el servicio Elixir: opción B

Usa la **opción B del proyecto**: le pide los avistamientos **al backend del P1 por HTTP**, con la biblioteca Req, en `GET /api/avistamientos`. No se conecta a la base de datos. La dirección del backend llega por la variable de entorno `BACKEND_URL` (`http://backend:3000`, el nombre del servicio dentro de la red de Docker). Eso vive en `datos.ex`, o sea en la cáscara: **el núcleo nunca sabe de dónde vinieron los datos**.

### 4.5 Bibliotecas del servicio Elixir

Elixir 1.18 sobre OTP 28, con Plug (rutas), Bandit (servidor), Jason (JSON) y Req (cliente HTTP). Sin Phoenix. Las versiones exactas quedan fijadas en `funcional/mix.lock`.

## 5. Las funcionalidades en Elixir

Los endpoints se pueden probar con el navegador o con `curl`, por ejemplo `http://localhost:8080/f/estadisticas?n=3`. Los números de los ejemplos cambian según los datos.

| Endpoint | Para qué |
|---|---|
| `GET /f/salud` | Responde `ok`; comprueba que el servicio está vivo |
| `GET /f/avistamientos` | Los avistamientos que lee Elixir (diagnóstico) |
| `GET /f/estadisticas?n=5` | Estadísticas (funcionalidad #3) |
| `GET /f/perdidos?dias=14` | Perros perdidos de vista (funcionalidad #7) |
| `GET /f/zonas?metros=500` | Zonas de concentración (funcionalidad #4) |

### 5.1 Estadísticas (catálogo #3)

- **Autor:** Diego Orlando Alonso Alvarado
- **Qué hace:** cuenta los avistamientos por color, por raza y por día, y calcula los `n` más comunes de colores y razas.
- **Cómo se usa en la app:** pestaña **Estadísticas**. Se escribe cuántos "más comunes" mostrar (por defecto 5) y se toca **Actualizar**. Aparecen tres gráficas de barras: colores más comunes, razas más comunes y avistamientos por día.
- **Endpoint:** `GET /f/estadisticas?n=5` (`n` es opcional; por defecto 5).

Ejemplo de respuesta:

```json
{
  "total": 115,
  "por_color": [{"nombre": "Cafe", "cantidad": 41}, {"nombre": "Negro", "cantidad": 38}],
  "por_raza": [{"nombre": "Sin raza definida / criollo", "cantidad": 97}, {"nombre": "Pastor Aleman", "cantidad": 14}],
  "por_dia": [{"nombre": "2026-09-28", "cantidad": 6}, {"nombre": "2026-10-20", "cantidad": 9}],
  "mas_comunes": {
    "colores": [{"nombre": "Cafe", "cantidad": 41}],
    "razas": [{"nombre": "Sin raza definida / criollo", "cantidad": 97}]
  }
}
```

| Requisito del paradigma | Dónde está (`funcional/lib/perritos/estadisticas.ex`) |
|---|---|
| Núcleo puro, separado de la cáscara | Todo el módulo `Perritos.Estadisticas`; la cáscara es `estadisticas_router.ex` |
| Sin estado mutable | Se cuenta con `Enum.reduce` y `Map.update`, sin contadores |
| Pattern matching y cláusulas múltiples | `nombre_raza/1` (perro con y sin raza) y `tomar/2` (tres cláusulas) |
| Función que recibe una función | `contar_por/2` |
| Función que regresa una función | `contador_por/1` |
| Recursión explícita | `tomar/2` (los primeros `n` elementos, sin `Enum.take`) |
| Composición con `\|>` | `mas_comunes/2`, `por_dia/1`, `resumen/2` |
| `Stream` | `contar_por/2` y `por_color/1`; las mismas funciones sirven sobre una lista o un `Stream` (hay una prueba que lo comprueba) |
| Pruebas y doctests | `funcional/test/estadisticas_test.exs`: 9 pruebas y 8 doctests |

### 5.2 Perros perdidos de vista (catálogo #7)

- **Autor:** Oscar Osvaldo Berlanga Sierra 
- **Qué hace:** lista los perros que llevan `n` días o más sin reportarse, agrupados por zona (cuadros de 0.01° de lado, cerca de 1 km), con los más antiguos primero. Como el P1 no distingue si dos registros son el mismo perro, **cada avistamiento cuenta como un perro**.
- **Cómo se usa en la app:** pestaña **Perdidos**. Se escribe el número de días (por defecto 14) y se toca **Buscar**. Aparecen las zonas, con la foto, el nombre y "hace N días" de cada perro.
- **Endpoint:** `GET /f/perdidos?dias=14` (`dias` es opcional; por defecto 14).

Ejemplo de respuesta:

```json
{
  "dias": 14,
  "zonas": [
    {
      "zona": "zona 25.46, -101.03",
      "cantidad": 2,
      "perros": [
        {"id": 19, "nombre": "Rocky", "foto": "356a618e-bef4-4fb4-a1d7-a71c8f2c44c4.jpg",
         "fecha": "2026-09-28T01:37:32", "dias": 28}
      ]
    }
  ]
}
```

| Requisito del paradigma | Dónde está (`funcional/lib/perritos/perdidos.ex`) |
|---|---|
| Núcleo puro, separado de la cáscara | Todo `Perritos.Perdidos`. El reloj se lee en `perdidos_router.ex` y llega al núcleo como el argumento `ahora` |
| Sin estado mutable | Todo se arma con listas y mapas nuevos |
| Pattern matching y cláusulas múltiples | `perdidos/3` (lista vacía aparte), `agrupar/3`, `meter/3` |
| Función que regresa una función | `llevan_sin_verse/2`, el filtro por antigüedad |
| Función que recibe una función | `agrupar_por/2` y `ordenar_con/2` |
| Recursión explícita | `agrupar/3` y `meter/3`: el agrupado está escrito a mano, sin `Enum.group_by` |
| Función de comparación | `mas_antiguo_primero/2`, pasada a `ordenar_con/2` |
| Composición con `\|>` | `perdidos/3`, `dias_sin_verse/2` |
| Pruebas y doctests | `funcional/test/perdidos_test.exs`: 10 pruebas y 8 doctests |

### 5.3 Zonas de concentración (catálogo #4)

- **Autor:** Jose Uriel Coronado Jaramillo ·
- **Qué hace:** divide la ciudad en una cuadrícula de celdas cuadradas (500 m por defecto), cuenta cuántos avistamientos caen en cada una y regresa los límites de cada celda para dibujarla en el mapa.
- **Cómo se usa en la app:** pestaña **Zonas**. Se ve el mapa con un rectángulo por celda, más rojo mientras más perros hay, y al tocar un rectángulo se ve cuántos avistamientos tiene. Se puede cambiar el tamaño de la celda en metros y tocar **Actualizar**.
- **Endpoint:** `GET /f/zonas?metros=500` (`metros` es opcional; por defecto 500).

Ejemplo de respuesta:

```json
{
  "metros": 500,
  "maximo": 6,
  "celdas": [
    {"sur": 25.457904, "oeste": -101.035288, "norte": 25.462396, "este": -101.030318, "cantidad": 6}
  ]
}
```

| Requisito del paradigma | Dónde está (`funcional/lib/perritos/zonas.ex`) |
|---|---|
| Núcleo puro, separado de la cáscara | Todo `Perritos.Zonas`; el frontend solo pinta lo que calcula el núcleo |
| Sin estado mutable | Se cuenta con `Enum.reduce` y `Map.update` |
| Pattern matching y cláusulas múltiples | `zonas/3` (lista vacía aparte) y `maximo/1` |
| Función que regresa una función | `celdas_de/2` |
| Función que recibe una función | `contar_celdas/2` |
| Recursión explícita | `maximo/1` |
| Composición con `\|>` | `contar_celdas/2`, `zonas/3` |
| `Stream` | `contar_celdas/2` procesa los avistamientos con `Stream.map` |
| Casos borde | Lista vacía, meridiano 0 (`floor` y no `trunc` con longitudes negativas), `metros` en cero o negativos |
| Pruebas y doctests | `funcional/test/zonas_test.exs`: 10 pruebas y 6 doctests |

## 6. Pruebas

Las pruebas del núcleo **no necesitan la base de datos ni el servidor**: `mix.exs` define el alias `test: "test --no-start"`. Se corren con Docker, sin instalar Elixir.

La primera vez, una sola vez, hay que instalar el gestor de paquetes y bajar las dependencias:

```bash
docker compose run --rm herramientas mix local.hex --force
docker compose run --rm herramientas mix local.rebar --force
docker compose run --rm herramientas mix deps.get
```

Y luego, cada vez que se quieran correr las pruebas de las tres funcionalidades:

```bash
docker compose run --rm herramientas mix test
```

Debe terminar con `0 failures`.

Aunque alguien tenga Elixir instalado, que no compile `funcional/` fuera de Docker: lo compilado para su sistema no sirve en el Linux del contenedor.

**Prueba de idempotencia del P1 (opcional):** necesita Node 20 instalado y la app levantada. Envía dos veces el mismo registro y comprueba que no se duplica:

```powershell
cd backend
$env:API_URL = "http://localhost:8080"
npm run prueba:doble-envio
```

## 7. Trabajo en equipo con Git

- Es el **mismo repositorio del P1**, sobre su rama principal, con todo el historial.
- Hay **un issue por funcionalidad**, asignado a su autor, y el último commit de cada una lo cierra con `Closes #n`. La infraestructura también tiene su issue.
- Cada funcionalidad se trabajó en **su propia rama** (`feature/estadisticas`, `feature/perdidos`, `feature/zonas`) y se fusionó a `main` cuando estuvo lista.
- Los commits de cada funcionalidad son de su autor, y los cambios al código del P1 que hizo falta tocar mencionan su issue (`refs #n`).

## 8. Problemas comunes

| Problema | Causa y solución |
|---|---|
| `no configuration file provided: not found` | Se corrió el comando fuera de la carpeta del repo. Entra a la raíz, donde está `docker-compose.yml` |
| `502 Bad Gateway` después de reconstruir algo | nginx se quedó con la dirección vieja de un contenedor. Corre `docker compose restart proxy` |
| `/f/...` da 404 o no carga la pestaña | Se abrió la app con Live Server. Las rutas `/f/` solo existen detrás del proxy: usa http://localhost:8080 o la URL del túnel |
| Cambié la contraseña en `.env` y MySQL no la toma | MySQL guarda la contraseña la primera vez que crea su volumen. Corre `docker compose down -v` y vuelve a levantar |
| El puerto 8080 está ocupado | Cambia `"8080:80"` en el servicio `proxy` de `docker-compose.yml` por otro puerto, como `"8081:80"` |
| La URL del túnel dejó de servir | Cambia al reiniciar el contenedor `tunel`. Vuelve a obtenerla con el comando de la sección 3.2 (paso 5) |
| El túnel no conecta en el WiFi de la escuela | Algunas redes bloquean el tráfico hacia Cloudflare. Prueba con datos móviles; si no, cambia el comando del servicio `tunel` agregando `--protocol http2` |
| Las fotos no se ven | El backend las copia de `database/fotos-prueba/` al arrancar. Revisa que esa carpeta tenga las fotos |
| `mix test` dice `environment variable ... is missing` | Falta el alias `test: "test --no-start"` en `funcional/mix.exs` |
| Errores raros al compilar Elixir | Se mezcló lo compilado en la máquina con lo del contenedor. Borra `funcional/_build` y `funcional/deps` y repite `mix deps.get` con `herramientas` |
| La cámara o la ubicación no funcionan | Solo funcionan con `https` o `localhost`. Desde el celular usa la URL del túnel |
| Un error de YAML en `docker-compose.yml` | Casi siempre es sangría. Revisa con `docker compose config --quiet` |

## 9. Estructura del repositorio

```
Registro_perritos/
├── docker-compose.yml        # db, backend, funcional, frontend, proxy, tunel y herramientas
├── .env.example              # variables que hay que definir (copiar a .env)
├── proxy/
│   └── nginx.conf            # reparte /, /api/ y /f/
├── backend/                  # API REST del P1 (Node.js + Express)
│   ├── Dockerfile
│   ├── server.js
│   ├── db.js
│   ├── imagenes.js
│   └── routes/               # perritos.js, catalogos.js, avistamientos.js
├── frontend/                 # interfaz (HTML, CSS y JS puro)
│   ├── Dockerfile
│   ├── index.html, app.js, style.css
│   ├── estadisticas.js / .css
│   ├── perdidos.js / .css
│   └── zonas.js / .css
├── funcional/                # servicio Elixir del P2
│   ├── Dockerfile            # dos etapas, con mix release
│   ├── mix.exs, mix.lock
│   ├── lib/perritos/         # núcleo (estadisticas, perdidos, zonas) y cáscara (routers, datos)
│   └── test/                 # pruebas ExUnit del núcleo
├── database/
│   ├── schema.sql            # tablas
│   ├── seed.sql              # catálogos de razas y colores
│   ├── seed-perritos.sql     # avistamientos de muestra
│   ├── fotos-prueba/         # fotos de los avistamientos de muestra
│   └── diagrama-entidad-relacion.png
├── capturas/                 # capturas de pantalla del P1
└── README.md
```