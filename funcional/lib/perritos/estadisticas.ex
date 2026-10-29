defmodule Perritos.Estadisticas do
  @moduledoc """
  Núcleo de la funcionalidad *Estadísticas*: conteos por color, por raza y por día,
  y los `n` más comunes.

  Todas las funciones son puras: reciben datos y regresan datos. No consultan la base
  de datos, no leen el reloj y no imprimen. Los avistamientos pueden llegar como lista
  o como `Stream` (cualquier cosa que se pueda enumerar).
  """

  @doc """
  Cuenta cuántas veces aparece cada clave que produce `fun_clave`.

  Es una función de orden superior: **recibe una función**. Procesa los elementos
  de forma perezosa con `Stream`, en una sola pasada.

      iex> Perritos.Estadisticas.contar_por(["ana", "luis", "eva"], &String.length/1)
      %{3 => 2, 4 => 1}
  """
  def contar_por(elementos, fun_clave) when is_function(fun_clave, 1) do
    elementos
    |> Stream.map(fun_clave)
    |> Enum.reduce(%{}, &sumar/2)
  end

  @doc """
  Regresa una **función** que cuenta por el campo indicado.

      iex> contar_por_raza = Perritos.Estadisticas.contador_por(:raza)
      iex> contar_por_raza.([%{raza: "Labrador"}, %{raza: "Poodle"}, %{raza: "Labrador"}])
      %{"Labrador" => 2, "Poodle" => 1}
  """
  def contador_por(campo) when is_atom(campo) do
    fn elementos -> contar_por(elementos, &Map.get(&1, campo)) end
  end

  @doc """
  Cuenta los avistamientos por color. Cada color de un perro cuenta
  (el principal y los adicionales).

      iex> Perritos.Estadisticas.por_color([%{colores: ["Negro", "Blanco"]}, %{colores: ["Negro"]}])
      %{"Negro" => 2, "Blanco" => 1}
  """
  def por_color(avistamientos) do
    avistamientos
    |> Stream.flat_map(& &1.colores)
    |> Enum.reduce(%{}, &sumar/2)
  end

  @doc """
  Cuenta los avistamientos por raza. Un perro sin raza (`nil`) se cuenta
  como "Sin raza definida".

      iex> Perritos.Estadisticas.por_raza([%{raza: nil}, %{raza: "Labrador"}, %{raza: nil}])
      %{"Sin raza definida" => 2, "Labrador" => 1}
  """
  def por_raza(avistamientos), do: contar_por(avistamientos, &nombre_raza/1)

  defp nombre_raza(%{raza: nil}), do: "Sin raza definida"
  defp nombre_raza(%{raza: raza}), do: raza

  @doc """
  Cuenta los avistamientos por día de calendario (no por horas).

      iex> Perritos.Estadisticas.por_dia([%{fecha: ~N[2026-10-19 08:00:00]}, %{fecha: ~N[2026-10-19 20:00:00]}])
      %{"2026-10-19" => 2}
  """
  def por_dia(avistamientos) do
    contar_por(avistamientos, fn a ->
      a.fecha |> NaiveDateTime.to_date() |> Date.to_iso8601()
    end)
  end

  @doc """
  Ordena unos conteos del más común al menos común. Si hay empate, desempata
  por orden alfabético para que el resultado siempre sea el mismo.

      iex> Perritos.Estadisticas.ordenar(%{"b" => 1, "a" => 1, "c" => 3})
      [{"c", 3}, {"a", 1}, {"b", 1}]
  """
  def ordenar(conteos) do
    Enum.sort_by(conteos, fn {clave, cantidad} -> {-cantidad, to_string(clave)} end)
  end

  @doc """
  Los `n` conteos más comunes.

      iex> Perritos.Estadisticas.mas_comunes(%{"a" => 1, "b" => 5, "c" => 3}, 2)
      [{"b", 5}, {"c", 3}]
  """
  def mas_comunes(conteos, n) do
    conteos
    |> ordenar()
    |> tomar(n)
  end

  # Recursión explícita: toma los primeros `n` elementos de una lista (sin usar Enum.take).
  defp tomar(_lista, n) when n <= 0, do: []
  defp tomar([], _n), do: []
  defp tomar([cabeza | resto], n), do: [cabeza | tomar(resto, n - 1)]

  @doc """
  Junta todas las estadísticas en un solo resultado.

  Nota: si `avistamientos` es un `Stream`, se recorre varias veces (una por estadística).

      iex> resumen = Perritos.Estadisticas.resumen([], 3)
      iex> resumen.total
      0
  """
  def resumen(avistamientos, n) do
    por_color = por_color(avistamientos)
    por_raza = por_raza(avistamientos)

    %{
      total: Enum.count(avistamientos),
      por_color: ordenar(por_color),
      por_raza: ordenar(por_raza),
      por_dia: avistamientos |> por_dia() |> Enum.sort(),
      mas_comunes_colores: mas_comunes(por_color, n),
      mas_comunes_razas: mas_comunes(por_raza, n)
    }
  end

  defp sumar(clave, conteos), do: Map.update(conteos, clave, 1, &(&1 + 1))
end