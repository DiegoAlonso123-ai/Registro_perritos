defmodule Perritos.Perdidos do
  @moduledoc """
  Núcleo de la funcionalidad *Perros perdidos de vista*: los perros que llevan
  `n` días o más sin reportarse, agrupados por zona.

  El Proyecto 1 no distingue si dos registros son el mismo perro, así que cada
  avistamiento cuenta como un perro.

  Todas las funciones son puras. En especial, la fecha de "hoy" llega como argumento
  (`ahora`): leer el reloj es un efecto, y le toca a la cáscara, no al núcleo.
  """

  @doc """
  Días de calendario que han pasado entre el avistamiento y `ahora`.
  Si la fecha del avistamiento es posterior a `ahora`, el resultado es negativo.

      iex> Perritos.Perdidos.dias_sin_verse(%{fecha: ~N[2026-10-10 08:00:00]}, ~N[2026-10-19 12:00:00])
      9
  """
  def dias_sin_verse(%{fecha: fecha}, ahora) do
    ahora
    |> NaiveDateTime.to_date()
    |> Date.diff(NaiveDateTime.to_date(fecha))
  end

  @doc """
  Regresa una **función** que dice si un avistamiento lleva `dias` días o más sin verse,
  visto desde `ahora`.

      iex> tres_dias = Perritos.Perdidos.llevan_sin_verse(3, ~N[2026-10-19 12:00:00])
      iex> tres_dias.(%{fecha: ~N[2026-10-16 08:00:00]})
      true
      iex> tres_dias.(%{fecha: ~N[2026-10-17 08:00:00]})
      false
  """
  def llevan_sin_verse(dias, ahora) do
    fn avistamiento -> dias_sin_verse(avistamiento, ahora) >= dias end
  end

  @doc """
  Función de comparación: el avistamiento más antiguo va primero.
  Con fechas iguales, conserva el orden original.

      iex> Perritos.Perdidos.mas_antiguo_primero(%{fecha: ~N[2026-10-01 08:00:00]}, %{fecha: ~N[2026-10-15 08:00:00]})
      true
  """
  def mas_antiguo_primero(a, b), do: NaiveDateTime.compare(a.fecha, b.fecha) != :gt

  @doc """
  Ordena avistamientos con la función de comparación que se le **reciba**.

      iex> viejo = %{fecha: ~N[2026-10-01 08:00:00]}
      iex> nuevo = %{fecha: ~N[2026-10-15 08:00:00]}
      iex> Perritos.Perdidos.ordenar_con([nuevo, viejo], &Perritos.Perdidos.mas_antiguo_primero/2) == [viejo, nuevo]
      true
  """
  def ordenar_con(avistamientos, comparador) when is_function(comparador, 2) do
    Enum.sort(avistamientos, comparador)
  end

  @doc """
  La zona de un avistamiento: una cuadrícula de 0.01 grados (cerca de 1 km).
  Los índices salen de `floor/1`, así que también funcionan con longitudes negativas.

      iex> Perritos.Perdidos.zona_de(%{lat: 25.4262, lon: -101.0275})
      {2542, -10103}
  """
  def zona_de(%{lat: lat, lon: lon}), do: {floor(lat * 100), floor(lon * 100)}

  @doc """
  Nombre legible de una zona (la esquina suroeste de su cuadro).

      iex> Perritos.Perdidos.nombre_zona({2542, -10103})
      "zona 25.42, -101.03"
  """
  def nombre_zona({fila, columna}), do: "zona #{coordenada(fila)}, #{coordenada(columna)}"

  defp coordenada(indice), do: :erlang.float_to_binary(indice / 100, decimals: 2)

  @doc """
  Agrupa una lista según la clave que produce `fun_clave` (recibe una **función**).
  Regresa una lista de `{clave, elementos}`, con los grupos en el orden en que
  aparece su primer elemento. Está escrita con recursión explícita.

      iex> Perritos.Perdidos.agrupar_por(["ana", "luis", "eva", "rosa"], &String.length/1)
      [{3, ["ana", "eva"]}, {4, ["luis", "rosa"]}]
  """
  def agrupar_por(elementos, fun_clave) when is_function(fun_clave, 1) do
    elementos
    |> agrupar([], fun_clave)
    |> Enum.map(fn {clave, grupo} -> {clave, Enum.reverse(grupo)} end)
  end

  defp agrupar([], grupos, _fun_clave), do: grupos

  defp agrupar([cabeza | resto], grupos, fun_clave) do
    agrupar(resto, meter(grupos, fun_clave.(cabeza), cabeza), fun_clave)
  end

  # Mete un elemento en el grupo de su clave, o crea el grupo al final si no existe.
  defp meter([], clave, elemento), do: [{clave, [elemento]}]

  defp meter([{clave, grupo} | resto], clave, elemento),
    do: [{clave, [elemento | grupo]} | resto]

  defp meter([otro | resto], clave, elemento), do: [otro | meter(resto, clave, elemento)]

  @doc """
  Los perros que llevan `dias` días o más sin verse, agrupados por zona.

  Los perros de cada zona van del más antiguo al más reciente, y las zonas van
  en el orden de su perro más antiguo.

      iex> viejo = %{id: 1, nombre: "Rocky", foto: "a.jpg", lat: 25.4262, lon: -101.0275, fecha: ~N[2026-10-01 08:00:00]}
      iex> [grupo] = Perritos.Perdidos.perdidos([viejo], 14, ~N[2026-10-19 12:00:00])
      iex> {grupo.zona, grupo.cantidad}
      {"zona 25.42, -101.03", 1}
  """
  def perdidos([], _dias, _ahora), do: []

  def perdidos(avistamientos, dias, ahora) do
    avistamientos
    |> Enum.filter(llevan_sin_verse(dias, ahora))
    |> ordenar_con(&mas_antiguo_primero/2)
    |> agrupar_por(&zona_de/1)
    |> Enum.map(fn {zona, perros} -> grupo(zona, perros, ahora) end)
  end

  defp grupo(zona, perros, ahora) do
    %{
      zona: nombre_zona(zona),
      cantidad: length(perros),
      perros: Enum.map(perros, &ficha(&1, ahora))
    }
  end

  defp ficha(avistamiento, ahora) do
    %{
      id: avistamiento.id,
      nombre: avistamiento.nombre,
      foto: avistamiento.foto,
      fecha: avistamiento.fecha,
      dias: dias_sin_verse(avistamiento, ahora)
    }
  end
end