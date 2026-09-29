

// ==========================================================
// Configuracion
// ==========================================================

const API_URL = `http://${location.hostname}:3000`;

// Clave de idempotencia compatible con PC y celular
function generarUUID() {
  if (window.crypto && typeof window.crypto.randomUUID === "function") {
    return window.crypto.randomUUID();
  }

  if (window.crypto && typeof window.crypto.getRandomValues === "function") {
    const bytes = new Uint8Array(16);
    window.crypto.getRandomValues(bytes);

    // UUID versión 4
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    const hex = Array.from(bytes).map(b =>
      b.toString(16).padStart(2, "0")
    );

    return (
      hex.slice(0, 4).join("") + "-" +
      hex.slice(4, 6).join("") + "-" +
      hex.slice(6, 8).join("") + "-" +
      hex.slice(8, 10).join("") + "-" +
      hex.slice(10, 16).join("")
    );
  }

  // Último respaldo
  return Date.now().toString(36) + "-" +
         Math.random().toString(36).substring(2);
}

let idempotencyKey = generarUUID();

// Huellas de las fotos ya registradas en esta sesion (para avisar si se repite la misma foto)
const huellasEnviadas = new Set();
const huellaDe = (archivo) => `${archivo.name}-${archivo.size}-${archivo.lastModified}`;

// ==========================================================
// Navegacion entre pestañas
// ==========================================================
const botonesTab = document.querySelectorAll(".tab-btn");
const contenidosTab = document.querySelectorAll(".tab-contenido");

botonesTab.forEach((boton) => {
  boton.addEventListener("click", () => {
    botonesTab.forEach((b) => b.classList.remove("activo"));
    contenidosTab.forEach((c) => c.classList.remove("activo"));

    boton.classList.add("activo");
    document.getElementById(`tab-${boton.dataset.tab}`).classList.add("activo");

    if (boton.dataset.tab === "mapa") {
      cargarMapaGeneral();
    }
    if (boton.dataset.tab === "lista") {
      cargarLista();
    }
  });
});

// ==========================================================
// Cargar catalogos (razas y colores) en los <select>
// ==========================================================
async function cargarCatalogos() {
  try {
    const [razas, colores] = await Promise.all([
      fetch(`${API_URL}/api/razas`).then((r) => r.json()),
      fetch(`${API_URL}/api/colores`).then((r) => r.json()),
    ]);

    const selectRaza = document.getElementById("raza_id");
    razas.forEach((raza) => {
      const opcion = document.createElement("option");
      opcion.value = raza.id;
      opcion.textContent = raza.nombre;
      selectRaza.appendChild(opcion);
    });

    const selectColorPrincipal = document.getElementById("color_principal_id");
    const selectColoresAdicionales = document.getElementById("colores_adicionales");
    colores.forEach((color) => {
      const opcion1 = document.createElement("option");
      opcion1.value = color.id;
      opcion1.textContent = color.nombre;
      selectColorPrincipal.appendChild(opcion1);

      const opcion2 = document.createElement("option");
      opcion2.value = color.id;
      opcion2.textContent = color.nombre;
      selectColoresAdicionales.appendChild(opcion2);
    });
  } catch (err) {
    console.error("No se pudieron cargar los catalogos:", err);
    mostrarMensaje("No se pudo conectar con el servidor. ¿Esta corriendo el backend?", "error");
  }
}

// ==========================================================
// Vista previa de la foto seleccionada
// ==========================================================
const inputFoto = document.getElementById("foto");
const previewFoto = document.getElementById("preview-foto");

inputFoto.addEventListener("change", () => {
  const archivo = inputFoto.files[0];
  if (archivo) {
    previewFoto.src = URL.createObjectURL(archivo);
    previewFoto.classList.remove("oculto");
  }

  // Arreglo para un bug de iOS/Safari: despues de elegir una foto (sobre todo con camara),
  // la pagina a veces deja de responder al tacto. Forzamos un pequeno scroll para "despertarla".
  setTimeout(() => {
    window.scrollTo(window.scrollX, window.scrollY + 1);
    window.scrollTo(window.scrollX, window.scrollY - 1);
  }, 300);
});

// ==========================================================
// Mapa del formulario de registro (pin arrastrable)
// ==========================================================
let mapaRegistro, marcadorRegistro;
let ubicacionActual = { lat: 25.4260, lng: -100.9959 }; // Saltillo por default

function iniciarMapaRegistro() {
  mapaRegistro = L.map("mapa-registro").setView([ubicacionActual.lat, ubicacionActual.lng], 13);

  L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
    attribution: "&copy; OpenStreetMap contributors",
  }).addTo(mapaRegistro);

  marcadorRegistro = L.marker([ubicacionActual.lat, ubicacionActual.lng], { draggable: true }).addTo(mapaRegistro);

  marcadorRegistro.on("dragend", () => {
    const pos = marcadorRegistro.getLatLng();
    actualizarUbicacion(pos.lat, pos.lng);
  });

  mapaRegistro.on("click", (e) => {
    marcadorRegistro.setLatLng(e.latlng);
    actualizarUbicacion(e.latlng.lat, e.latlng.lng);
  });

  actualizarUbicacion(ubicacionActual.lat, ubicacionActual.lng);
}

function actualizarUbicacion(lat, lng) {
  ubicacionActual = { lat, lng };
  document.getElementById("coords-actuales").textContent =
    `Ubicacion seleccionada: ${lat.toFixed(6)}, ${lng.toFixed(6)}`;
}

document.getElementById("btn-mi-ubicacion").addEventListener("click", () => {
  if (!navigator.geolocation) {
    mostrarMensaje("Tu navegador no soporta geolocalizacion", "error");
    return;
  }
  navigator.geolocation.getCurrentPosition(
    (pos) => {
      const { latitude, longitude } = pos.coords;
      mapaRegistro.setView([latitude, longitude], 15);
      marcadorRegistro.setLatLng([latitude, longitude]);
      actualizarUbicacion(latitude, longitude);
    },
    (err) => {
      mostrarMensaje("No se pudo obtener tu ubicacion: " + err.message, "error");
    }
  );
});

// ==========================================================
// Envio del formulario (con validacion e idempotencia)
// ==========================================================
const form = document.getElementById("form-perrito");

function mostrarMensaje(texto, tipo) {
  const div = document.getElementById("mensaje-form");
  div.textContent = texto;
  div.className = `mensaje ${tipo}`;
}

form.addEventListener("submit", async (e) => {
  e.preventDefault();
  mostrarMensaje("", "");

  const nombre = document.getElementById("nombre").value.trim();
  const razaId = document.getElementById("raza_id").value;
  const colorPrincipalId = document.getElementById("color_principal_id").value;
  const coloresSeleccionados = Array.from(document.getElementById("colores_adicionales").selectedOptions).map(
    (op) => Number(op.value)
  );
  const archivoFoto = inputFoto.files[0];

  // --- Validaciones del lado del cliente (el backend tambien valida, esto es solo para dar feedback rapido) ---
  if (!nombre) return mostrarMensaje("Falta el nombre", "error");
  if (!colorPrincipalId) return mostrarMensaje("Falta el color principal", "error");
  if (!archivoFoto) return mostrarMensaje("Falta la foto", "error");
  if (coloresSeleccionados.length > 2) return mostrarMensaje("Maximo 2 colores adicionales", "error");
  if (coloresSeleccionados.includes(Number(colorPrincipalId))) {
    return mostrarMensaje("Un color adicional no puede repetir el color principal", "error");
  }

  // --- Aviso si es la misma foto que ya se registro en esta sesion ---
  if (huellasEnviadas.has(huellaDe(archivoFoto))) {
    const seguro = confirm("Ya registraste un perrito con esta misma foto. ¿Quieres registrarlo de nuevo?");
    if (!seguro) return;
  }

  const datos = new FormData();
  datos.append("nombre", nombre);
  if (razaId) datos.append("raza_id", razaId);
  datos.append("color_principal_id", colorPrincipalId);
  if (coloresSeleccionados.length > 0) {
    datos.append("colores_adicionales", JSON.stringify(coloresSeleccionados));
  }
  datos.append("ubicacion_lat", ubicacionActual.lat);
  datos.append("ubicacion_lng", ubicacionActual.lng);
  datos.append("idempotency_key", idempotencyKey);
  datos.append("foto", archivoFoto);

  try {
    document.getElementById("btn-guardar").disabled = true;
    const res = await fetch(`${API_URL}/api/perritos`, { method: "POST", body: datos });
    const data = await res.json();

    if (!res.ok) {
      mostrarMensaje(data.error || "Ocurrio un error al registrar el perrito", "error");
      return;
    }

    if (data.duplicado_evitado) {
      mostrarExito("Este perrito ya estaba registrado", "No se creó un registro nuevo.");
    } else {
      mostrarExito("¡Perrito registrado!", `${data.nombre} se guardó correctamente.`);
    }
    huellasEnviadas.add(huellaDe(archivoFoto));
    form.reset();
    previewFoto.classList.add("oculto");
   idempotencyKey = generarUUID(); // nueva clave para el SIGUIENTE perrito
  } catch (err) {
    console.error(err);
    mostrarMensaje("No se pudo conectar con el servidor", "error");
  } finally {
    document.getElementById("btn-guardar").disabled = false;
  }
});

// ==========================================================
// Mapa general (todos los perritos)
// ==========================================================
let mapaGeneral;
let mapaGeneralIniciado = false;

async function cargarMapaGeneral() {
  if (!mapaGeneralIniciado) {
    mapaGeneral = L.map("mapa-general").setView([ubicacionActual.lat, ubicacionActual.lng], 12);
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap contributors",
    }).addTo(mapaGeneral);
    mapaGeneralIniciado = true;
  }

  try {
    const perritos = await fetch(`${API_URL}/api/perritos`).then((r) => r.json());

    // Limpiamos marcadores anteriores antes de volver a dibujar
    mapaGeneral.eachLayer((capa) => {
      if (capa instanceof L.Marker) mapaGeneral.removeLayer(capa);
    });

    perritos.forEach((perrito) => {
      const marcador = L.marker([Number(perrito.ubicacion_lat), Number(perrito.ubicacion_lng)]).addTo(mapaGeneral);
      marcador.bindPopup(`
        <div class="popup-perrito">
          <img src="${API_URL}/api/imagenes/${perrito.foto_filename}" />
          <h3>${perrito.nombre}</h3>
          <p>${perrito.raza || "Sin raza especificada"}</p>
          <p>Color: ${perrito.color_principal}</p>
        </div>
      `);
    });
  } catch (err) {
    console.error("No se pudo cargar el mapa general:", err);
  }
}

// ==========================================================
// Lista de perritos + detalle
// ==========================================================
async function cargarLista() {
  const contenedor = document.getElementById("lista-perritos");
  contenedor.innerHTML = "<p>Cargando...</p>";

  try {
    const perritos = await fetch(`${API_URL}/api/perritos`).then((r) => r.json());

    if (perritos.length === 0) {
      contenedor.innerHTML = "<p>Todavia no hay perritos registrados.</p>";
      return;
    }

    contenedor.innerHTML = "";
    perritos.forEach((perrito) => {
      const tarjeta = document.createElement("div");
      tarjeta.className = "tarjeta-perrito";
      tarjeta.innerHTML = `
        <img src="${API_URL}/api/imagenes/${perrito.foto_filename}" alt="${perrito.nombre}" />
        <div class="info">
          <h3>${perrito.nombre}</h3>
          <p>${perrito.color_principal}</p>
        </div>
      `;
      tarjeta.addEventListener("click", () => abrirDetalle(perrito.id));
      contenedor.appendChild(tarjeta);
    });
  } catch (err) {
    console.error(err);
    contenedor.innerHTML = "<p>Error al cargar los perritos.</p>";
  }
}

const modal = document.getElementById("modal-detalle");

async function abrirDetalle(id) {
  try {
    const perrito = await fetch(`${API_URL}/api/perritos/${id}`).then((r) => r.json());
    const coloresExtra = perrito.colores_adicionales.length
      ? perrito.colores_adicionales.join(", ")
      : "Ninguno";

    document.getElementById("detalle-cuerpo").innerHTML = `
      <img src="${API_URL}/api/imagenes/${perrito.foto_filename}" alt="${perrito.nombre}" />
      <h2>${perrito.nombre}</h2>
      <p><strong>Raza:</strong> ${perrito.raza || "Sin especificar"}</p>
      <p><strong>Color principal:</strong> ${perrito.color_principal}</p>
      <p><strong>Colores adicionales:</strong> ${coloresExtra}</p>
      <p><strong>Registrado:</strong> ${new Date(perrito.fecha_registro).toLocaleString()}</p>
      <p><strong>Ubicacion:</strong> ${Number(perrito.ubicacion_lat).toFixed(5)}, ${Number(perrito.ubicacion_lng).toFixed(5)}</p>
    `;
    modal.classList.remove("oculto");
  } catch (err) {
    console.error(err);
  }
}

document.getElementById("cerrar-modal").addEventListener("click", () => {
  modal.classList.add("oculto");
});
modal.addEventListener("click", (e) => {
  if (e.target === modal) modal.classList.add("oculto");
});

// ==========================================================
// Cuadro de "perrito registrado"
// ==========================================================
const modalExito = document.getElementById("modal-exito");

function mostrarExito(titulo, texto) {
  document.getElementById("exito-titulo").textContent = titulo;
  document.getElementById("exito-texto").textContent = texto;
  modalExito.classList.remove("oculto");
}

document.getElementById("btn-registrar-otro").addEventListener("click", () => {
  modalExito.classList.add("oculto");
  window.scrollTo({ top: 0, behavior: "smooth" });
});

document.getElementById("btn-ver-lista").addEventListener("click", () => {
  modalExito.classList.add("oculto");
  document.querySelector('.tab-btn[data-tab="lista"]').click();
});

// ==========================================================
// Inicio
// ==========================================================
cargarCatalogos();
iniciarMapaRegistro();