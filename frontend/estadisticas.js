// Pestaña "Estadísticas": pide /f/estadisticas y dibuja barras con <div> (sin librerías).
// Las rutas /f/... solo existen detrás del proxy: abrir la app en http://localhost:8080
(function () {
  const boton = document.querySelector('.tab-btn[data-tab="estadisticas"]');
  const contenido = document.getElementById("estadisticas-contenido");
  const inputN = document.getElementById("estadisticas-n");

  // Crea un elemento con texto seguro (textContent): los nombres vienen de usuarios.
  function elemento(etiqueta, texto, clase) {
    const el = document.createElement(etiqueta);
    if (texto !== undefined) el.textContent = texto;
    if (clase) el.className = clase;
    return el;
  }

  // Una gráfica de barras horizontales: cada fila es { nombre, cantidad }.
  function grafica(titulo, filas) {
    const caja = elemento("section", undefined, "est-grafica");
    caja.appendChild(elemento("h3", titulo));

    if (filas.length === 0) {
      caja.appendChild(elemento("p", "Todavía no hay datos.", "est-aviso"));
      return caja;
    }

    const maximo = Math.max(...filas.map((fila) => fila.cantidad));
    filas.forEach((fila) => {
      const linea = elemento("div", undefined, "est-fila");
      const pista = elemento("div", undefined, "est-pista");
      const barra = elemento("div", undefined, "est-barra");
      barra.style.width = `${(fila.cantidad / maximo) * 100}%`;
      pista.appendChild(barra);

      linea.append(
        elemento("span", fila.nombre, "est-nombre"),
        pista,
        elemento("span", String(fila.cantidad), "est-cantidad")
      );
      caja.appendChild(linea);
    });
    return caja;
  }

  async function cargar() {
    contenido.replaceChildren(elemento("p", "Cargando...", "est-aviso"));

    try {
      const n = Number(inputN.value) || 5;
      const res = await fetch(`/f/estadisticas?n=${n}`);
      if (!res.ok) throw new Error(`respuesta ${res.status}`);
      const datos = await res.json();

      contenido.replaceChildren(
        elemento("p", `${datos.total} avistamientos registrados`, "est-total"),
        grafica(`Los ${n} colores más comunes`, datos.mas_comunes.colores),
        grafica(`Las ${n} razas más comunes`, datos.mas_comunes.razas),
        grafica("Avistamientos por día", datos.por_dia)
      );
    } catch (err) {
      console.error(err);
      contenido.replaceChildren(
        elemento(
          "p",
          "No se pudieron cargar las estadísticas. Abre la app en http://localhost:8080 (con Docker levantado).",
          "est-aviso est-error"
        )
      );
    }
  }

  boton.addEventListener("click", cargar);
  document.getElementById("estadisticas-actualizar").addEventListener("click", cargar);
})();