defmodule Perritos.EstadisticasTest do
  use ExUnit.Case, async: true
  doctest Perritos.Estadisticas

  alias Perritos.{Avistamiento, Estadisticas}

  defp perro(id, colores, raza, fecha) do
    %Avistamiento{id: id, nombre: "Perro #{id}", colores: colores, raza: raza, fecha: fecha}
  end

  defp datos do
    [
      perro(1, ["Negro", "Blanco"], nil, ~N[2026-10-18 09:00:00]),
      perro(2, ["Negro"], "Labrador", ~N[2026-10-18 21:30:00]),
      perro(3, ["Cafe", "Blanco"], nil, ~N[2026-10-19 08:00:00])
    ]
  end

  test "lista vacía: todo en cero y sin listas con datos" do
    assert Estadisticas.resumen([], 3) == %{
             total: 0,
             por_color: [],
             por_raza: [],
             por_dia: [],
             mas_comunes_colores: [],
             mas_comunes_razas: []
           }
  end

  test "por_color cuenta todos los colores de cada perro, no solo el principal" do
    assert Estadisticas.por_color(datos()) == %{"Negro" => 2, "Blanco" => 2, "Cafe" => 1}
  end

  test "por_raza cuenta los perros sin raza como 'Sin raza definida'" do
    assert Estadisticas.por_raza(datos()) == %{"Sin raza definida" => 2, "Labrador" => 1}
  end

  test "por_dia agrupa por día de calendario, sin importar la hora" do
    assert Estadisticas.por_dia(datos()) == %{"2026-10-18" => 2, "2026-10-19" => 1}
  end

  test "empate entre los más comunes: desempata por orden alfabético" do
    conteos = %{"Cafe" => 2, "Blanco" => 2, "Negro" => 2}
    assert Estadisticas.mas_comunes(conteos, 2) == [{"Blanco", 2}, {"Cafe", 2}]
  end

  test "n mayor que los datos regresa todos, y n cero o negativo regresa lista vacía" do
    conteos = %{"a" => 1, "b" => 2}
    assert Estadisticas.mas_comunes(conteos, 10) == [{"b", 2}, {"a", 1}]
    assert Estadisticas.mas_comunes(conteos, 0) == []
    assert Estadisticas.mas_comunes(conteos, -3) == []
  end

  test "las mismas funciones dan el mismo resultado con una lista o con un Stream" do
    como_stream = Stream.map(datos(), & &1)
    assert Estadisticas.por_color(como_stream) == Estadisticas.por_color(datos())
    assert Estadisticas.resumen(como_stream, 2) == Estadisticas.resumen(datos(), 2)
  end

  test "contador_por regresa una función que sirve para cualquier campo" do
    por_raza = Estadisticas.contador_por(:raza)
    assert is_function(por_raza, 1)
    assert por_raza.(datos()) == %{nil => 2, "Labrador" => 1}
  end

  test "resumen junta todo, con los días en orden cronológico" do
    resumen = Estadisticas.resumen(datos(), 1)

    assert resumen.total == 3
    assert resumen.por_dia == [{"2026-10-18", 2}, {"2026-10-19", 1}]
    assert resumen.mas_comunes_colores == [{"Blanco", 2}]
    assert resumen.mas_comunes_razas == [{"Sin raza definida", 2}]
  end
end