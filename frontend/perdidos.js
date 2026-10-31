// Pestaña "Perdidos": pide /f/perdidos y muestra, por zona, los perros que llevan
// varios días sin reportarse. Las rutas /f/... solo existen detrás del proxy:
// abrir la app en http://localhost:8080
(function () {
  const contenido = document.getElementById("perdidos-contenido");
  const inputDias = document.getElementById("perdidos-dias");

  // Crea un elemento con texto seguro (textContent): los nombres vienen de usuarios.
  function elemento(etiqueta, texto, clase) {
    const el = document.createElement(etiqueta);
    if (texto !== undefined) el.textContent = texto;
    if (clase) el.className = clase;
    return el;
  }

  function textoDias(dias) {
    return dias === 1 ? "hace 1 día" : `hace ${dias} días`;
  }

  function tarjeta(perro) {
    const caja = elemento("div", undefined, "per-tarjeta");
    const foto = document.createElement("img");
    foto.src = `/api/imagenes/${encodeURIComponent(perro.foto)}`;
    foto.alt = perro.nombre;
    foto.loading = "lazy";

    caja.append(foto, elemento("strong", perro.nombre), elemento("span", textoDias(perro.dias)));
    return caja;
  }

  function zona(grupo) {
    const caja = elemento("section", undefined, "per-grupo");
    const etiqueta = grupo.cantidad === 1 ? "perro" : "perros";
    caja.appendChild(elemento("h3", `${grupo.zona} · ${grupo.cantidad} ${etiqueta}`));

    const lista = elemento("div", undefined, "per-lista");
    lista.append(...grupo.perros.map(tarjeta));
    caja.appendChild(lista);
    return caja;
  }

  async function cargar() {
    contenido.replaceChildren(elemento("p", "Cargando...", "per-aviso"));

    try {
      const dias = Number(inputDias.value) || 14;
      const res = await fetch(`/f/perdidos?dias=${dias}`);
      if (!res.ok) throw new Error(`respuesta ${res.status}`);
      const datos = await res.json();
      const total = datos.zonas.reduce((suma, grupo) => suma + grupo.cantidad, 0);

      if (total === 0) {
        contenido.replaceChildren(
          elemento("p", `Ningún perro lleva ${dias} días o más sin verse.`, "per-aviso")
        );
        return;
      }

      contenido.replaceChildren(
        elemento("p", `${total} avistamientos llevan ${dias} días o más sin reportarse`, "per-total"),
        ...datos.zonas.map(zona)
      );
    } catch (err) {
      console.error(err);
      contenido.replaceChildren(
        elemento(
          "p",
          "No se pudo cargar la lista. Abre la app en http://localhost:8080 (con Docker levantado).",
          "per-aviso per-error"
        )
      );
    }
  }

  document
    .querySelector('.tab-btn[data-tab="perdidos"]')
    .addEventListener("click", cargar);
  document.getElementById("perdidos-buscar").addEventListener("click", cargar);
})();