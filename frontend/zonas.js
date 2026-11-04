// Pestaña "Zonas": pide /f/zonas y pinta sobre el mapa un rectángulo por cada celda
// de la cuadrícula; mientras más avistamientos, más rojo. El frontend solo pinta:
// los límites de cada celda los calcula el servicio Elixir.
// Las rutas /f/... solo existen detrás del proxy: abrir la app en http://localhost:8080
(function () {
  const inputMetros = document.getElementById("zonas-metros");
  const resumen = document.getElementById("zonas-resumen");
  let mapa = null;
  let capa = null;

  function iniciarMapa() {
    mapa = L.map("zonas-mapa").setView([25.426, -100.9959], 12);
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap contributors",
    }).addTo(mapa);
    capa = L.layerGroup().addTo(mapa);
  }

  function pintar(datos) {
    capa.clearLayers();

    datos.celdas.forEach((celda) => {
      const intensidad = celda.cantidad / datos.maximo;
      const etiqueta = celda.cantidad === 1 ? "avistamiento" : "avistamientos";

      L.rectangle(
        [
          [celda.sur, celda.oeste],
          [celda.norte, celda.este],
        ],
        {
          color: "#b85f28",
          weight: 1,
          fillColor: "#c0392b",
          fillOpacity: 0.2 + 0.6 * intensidad,
        }
      )
        .bindPopup(`${celda.cantidad} ${etiqueta} en esta celda`)
        .addTo(capa);
    });

    if (datos.celdas.length > 0) {
      const limites = L.latLngBounds(
        datos.celdas.flatMap((celda) => [
          [celda.sur, celda.oeste],
          [celda.norte, celda.este],
        ])
      );
      mapa.fitBounds(limites, { padding: [20, 20] });
    }
  }

  async function cargar() {
    resumen.textContent = "Cargando...";
    resumen.className = "zon-resumen";

    try {
      const metros = Number(inputMetros.value) || 500;
      const res = await fetch(`/f/zonas?metros=${metros}`);
      if (!res.ok) throw new Error(`respuesta ${res.status}`);
      const datos = await res.json();
      const total = datos.celdas.reduce((suma, celda) => suma + celda.cantidad, 0);

      pintar(datos);
      resumen.textContent =
        total === 0
          ? "Todavía no hay avistamientos."
          : `${total} avistamientos en ${datos.celdas.length} celdas de ${datos.metros} m. ` +
            `La más concentrada tiene ${datos.maximo}. Más rojo = más perros.`;
    } catch (err) {
      console.error(err);
      resumen.textContent =
        "No se pudieron cargar las zonas. Abre la app en http://localhost:8080 (con Docker levantado).";
      resumen.className = "zon-resumen zon-error";
    }
  }

  function mostrar() {
    if (mapa === null) iniciarMapa();
    // El mapa se crea con la pestaña oculta; hay que avisarle de su tamaño real.
    setTimeout(() => mapa.invalidateSize(), 0);
    cargar();
  }

  document.querySelector('.tab-btn[data-tab="zonas"]').addEventListener("click", mostrar);
  document.getElementById("zonas-actualizar").addEventListener("click", cargar);
})();