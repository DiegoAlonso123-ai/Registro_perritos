defmodule Perritos.PerdidosTest do
  use ExUnit.Case, async: true
  doctest Perritos.Perdidos

  alias Perritos.{Avistamiento, Perdidos}

  @ahora ~N[2026-10-19 12:00:00]

  defp perro(id, lat, lon, fecha) do
    %Avistamiento{
      id: id,
      nombre: "Perro #{id}",
      foto: "#{id}.jpg",
      colores: ["Negro"],
      raza: nil,
      lat: lat,
      lon: lon,
      fecha: fecha
    }
  end

  test "lista vacía: no hay perros perdidos" do
    assert Perdidos.perdidos([], 14, @ahora) == []
  end

  test "si todos se vieron hace poco, no hay perdidos" do
    recientes = [
      perro(1, 25.4262, -101.0275, ~N[2026-10-18 09:00:00]),
      perro(2, 25.4262, -101.0275, ~N[2026-10-15 09:00:00])
    ]

    assert Perdidos.perdidos(recientes, 14, @ahora) == []
  end

  test "un perro con exactamente n días sin verse ya cuenta como perdido" do
    justo = perro(1, 25.4262, -101.0275, ~N[2026-10-05 08:00:00])

    assert [%{cantidad: 1, perros: [%{id: 1, dias: 14}]}] = Perdidos.perdidos([justo], 14, @ahora)
  end

  test "una fecha futura no truena y no cuenta como perdido" do
    futuro = perro(1, 25.4262, -101.0275, ~N[2026-10-25 08:00:00])

    assert Perdidos.perdidos([futuro], 1, @ahora) == []
    assert Perdidos.dias_sin_verse(futuro, @ahora) == -6
  end

  test "los días se cuentan por calendario, no por horas" do
    ayer = perro(1, 25.4262, -101.0275, ~N[2026-10-18 23:59:00])

    assert Perdidos.dias_sin_verse(ayer, ~N[2026-10-19 00:01:00]) == 1
    assert Perdidos.dias_sin_verse(ayer, ~N[2026-10-18 23:59:00]) == 0
  end

  test "agrupa por zona; en cada zona y entre zonas va primero el más antiguo" do
    # ids 1 y 3 están en la misma zona; el 2 en otra
    avistamientos = [
      perro(1, 25.4262, -101.0275, ~N[2026-10-03 08:00:00]),
      perro(2, 25.5155, -100.9055, ~N[2026-10-02 08:00:00]),
      perro(3, 25.4270, -101.0280, ~N[2026-10-01 08:00:00])
    ]

    resultado = Perdidos.perdidos(avistamientos, 7, @ahora)

    assert Enum.map(resultado, & &1.zona) == ["zona 25.42, -101.03", "zona 25.51, -100.91"]
    assert Enum.map(resultado, fn grupo -> Enum.map(grupo.perros, & &1.id) end) == [[3, 1], [2]]
    assert Enum.map(resultado, & &1.cantidad) == [2, 1]
  end

  test "llevan_sin_verse regresa una función que sirve como filtro" do
    filtro = Perdidos.llevan_sin_verse(10, @ahora)
    viejo = perro(1, 25.4262, -101.0275, ~N[2026-09-20 08:00:00])
    nuevo = perro(2, 25.4262, -101.0275, ~N[2026-10-18 08:00:00])

    assert is_function(filtro, 1)
    assert Enum.filter([viejo, nuevo], filtro) == [viejo]
  end

  test "ordenar_con acepta cualquier función de comparación" do
    viejo = perro(1, 25.4262, -101.0275, ~N[2026-10-01 08:00:00])
    nuevo = perro(2, 25.4262, -101.0275, ~N[2026-10-15 08:00:00])
    mas_reciente_primero = fn a, b -> NaiveDateTime.compare(a.fecha, b.fecha) != :lt end

    assert Perdidos.ordenar_con([viejo, nuevo], mas_reciente_primero) == [nuevo, viejo]
  end

  test "agrupar_por con lista vacía regresa lista vacía" do
    assert Perdidos.agrupar_por([], &Perdidos.zona_de/1) == []
  end

  test "las longitudes negativas caen en la zona correcta (floor, no truncar)" do
    assert Perdidos.zona_de(%{lat: 25.0, lon: -0.005}) == {2500, -1}
    assert Perdidos.zona_de(%{lat: 25.0, lon: 0.005}) == {2500, 0}
  end
end