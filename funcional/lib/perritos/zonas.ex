defmodule Perritos.Zonas do
  @moduledoc """
  Núcleo de la funcionalidad *Zonas de concentración*: divide la ciudad en una
  cuadrícula de celdas de `metros` de lado y cuenta cuántos avistamientos caen
  en cada celda.

  Todas las funciones son puras: reciben datos y regresan datos. No consultan la base
  de datos ni dibujan nada; el frontend solo pinta lo que aquí se calcula.
  """

  # Metros que mide 1 grado de latitud
  @metros_por_grado 111_320
  # Latitud de referencia (Saltillo) para calcular cuánto mide 1 grado de longitud
  @lat_ref 25.42

  @doc """
  Tamaño de una celda en grados: `{alto_en_latitud, ancho_en_longitud}`.
  Un grado de longitud mide menos al alejarse del ecuador, por eso se usa el coseno
  de la latitud de referencia.

      iex> {alto, ancho} = Perritos.Zonas.tamano_celda(1113.2, 0)
      iex> {Float.round(alto, 6), Float.round(ancho, 6)}
      {0.01, 0.01}
  """
  def tamano_celda(metros, lat_ref \\ @lat_ref) do
    alto = metros / @metros_por_grado
    ancho = metros / (@metros_por_grado * :math.cos(grados_a_radianes(lat_ref)))
    {alto, ancho}
  end

  defp grados_a_radianes(grados), do: grados * :math.pi() / 180

  @doc """
  La celda de un avistamiento, como `{fila, columna}`. Usa `floor/1` y no `trunc/1`
  para que las longitudes negativas (como las de Saltillo) caigan en la celda correcta.

      iex> tamano = Perritos.Zonas.tamano_celda(500)
      iex> Perritos.Zonas.celda(%{lat: 0.0001, lon: -0.0001}, tamano)
      {0, -1}
  """
  def celda(%{lat: lat, lon: lon}, {alto, ancho}), do: {floor(lat / alto), floor(lon / ancho)}

  @doc """
  Regresa una **función** que dice en qué celda cae un avistamiento, para celdas de
  `metros` de lado.

      iex> celda_de = Perritos.Zonas.celdas_de(500)
      iex> celda_de.(%{lat: 0.0001, lon: 0.0001})
      {0, 0}
  """
  def celdas_de(metros, lat_ref \\ @lat_ref) do
    tamano = tamano_celda(metros, lat_ref)
    fn avistamiento -> celda(avistamiento, tamano) end
  end

  @doc """
  Cuenta cuántos avistamientos hay en cada celda. **Recibe una función**
  (`fun_celda`) que decide la celda de cada avistamiento.

      iex> Perritos.Zonas.contar_celdas([1, 2, 3, 4, 5], fn n -> rem(n, 2) end)
      %{0 => 2, 1 => 3}
  """
  def contar_celdas(avistamientos, fun_celda) when is_function(fun_celda, 1) do
    avistamientos
    |> Stream.map(fun_celda)
    |> Enum.reduce(%{}, fn celda, conteos -> Map.update(conteos, celda, 1, &(&1 + 1)) end)
  end

  @doc """
  El valor más grande de una lista de cantidades (0 si está vacía).
  Escrita con recursión explícita.

      iex> Perritos.Zonas.maximo([3, 7, 2])
      7
  """
  def maximo([]), do: 0
  def maximo([cabeza | resto]), do: max(cabeza, maximo(resto))

  @doc """
  Las celdas con avistamientos y cuántos tiene cada una. Cada celda trae sus límites
  en grados (`sur`, `oeste`, `norte`, `este`) para que el frontend pueda dibujarla,
  y van de la más concentrada a la menos.

      iex> av = %{lat: 25.4, lon: -101.0}
      iex> resultado = Perritos.Zonas.zonas([av, av], 500)
      iex> {resultado.maximo, Enum.map(resultado.celdas, & &1.cantidad)}
      {2, [2]}
  """
  def zonas(avistamientos, metros, lat_ref \\ @lat_ref)

  def zonas([], metros, _lat_ref) when metros > 0, do: %{metros: metros, maximo: 0, celdas: []}

  def zonas(avistamientos, metros, lat_ref) when metros > 0 do
    tamano = tamano_celda(metros, lat_ref)
    conteos = contar_celdas(avistamientos, celdas_de(metros, lat_ref))

    %{
      metros: metros,
      maximo: conteos |> Map.values() |> maximo(),
      celdas:
        conteos
        |> Enum.map(fn {celda, cantidad} -> limites(celda, tamano, cantidad) end)
        |> Enum.sort_by(&{-&1.cantidad, &1.sur, &1.oeste})
    }
  end

  defp limites({fila, columna}, {alto, ancho}, cantidad) do
    %{
      sur: redondear(fila * alto),
      oeste: redondear(columna * ancho),
      norte: redondear((fila + 1) * alto),
      este: redondear((columna + 1) * ancho),
      cantidad: cantidad
    }
  end

  defp redondear(grados), do: Float.round(grados, 6)
end