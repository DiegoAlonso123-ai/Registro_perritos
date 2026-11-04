defmodule Perritos.ZonasTest do
  use ExUnit.Case, async: true
  doctest Perritos.Zonas

  alias Perritos.{Avistamiento, Zonas}

  defp perro(id, lat, lon) do
    %Avistamiento{id: id, nombre: "Perro #{id}", lat: lat, lon: lon, colores: ["Negro"]}
  end

  test "lista vacía: sin celdas y con máximo cero" do
    assert Zonas.zonas([], 500) == %{metros: 500, maximo: 0, celdas: []}
  end

  test "dos avistamientos en el mismo punto caen en una sola celda con cantidad 2" do
    resultado = Zonas.zonas([perro(1, 25.4123, -100.9876), perro(2, 25.4123, -100.9876)], 500)

    assert resultado.maximo == 2
    assert [%{cantidad: 2}] = resultado.celdas
  end

  test "avistamientos lejanos (unos 2 km) caen en celdas distintas" do
    resultado = Zonas.zonas([perro(1, 25.40, -101.0), perro(2, 25.42, -101.0)], 500)

    assert resultado.maximo == 1
    assert Enum.map(resultado.celdas, & &1.cantidad) == [1, 1]
  end

  test "con celdas más grandes, avistamientos cercanos se juntan en una sola" do
    cercanos = [perro(1, 25.4001, -101.0), perro(2, 25.4010, -101.0)]

    assert [%{cantidad: 2}] = Zonas.zonas(cercanos, 5000).celdas
  end

  test "a los dos lados del meridiano 0 las celdas son distintas (floor, no truncar)" do
    tamano = Zonas.tamano_celda(500)

    assert Zonas.celda(%{lat: 0.0001, lon: -0.0001}, tamano) == {0, -1}
    assert Zonas.celda(%{lat: 0.0001, lon: 0.0001}, tamano) == {0, 0}
  end

  test "los límites de la celda contienen al avistamiento" do
    av = perro(1, 25.4123, -100.9876)
    [celda] = Zonas.zonas([av], 500).celdas

    assert celda.sur <= av.lat and av.lat <= celda.norte
    assert celda.oeste <= av.lon and av.lon <= celda.este
  end

  test "las celdas salen de la más concentrada a la menos" do
    avistamientos = [perro(1, 25.40, -101.0), perro(2, 25.42, -101.0), perro(3, 25.42, -101.0)]

    assert Enum.map(Zonas.zonas(avistamientos, 500).celdas, & &1.cantidad) == [2, 1]
  end

  test "celdas_de regresa una función equivalente a celda con el tamaño de esos metros" do
    av = perro(1, 25.4123, -100.9876)
    celda_de = Zonas.celdas_de(500)

    assert is_function(celda_de, 1)
    assert celda_de.(av) == Zonas.celda(av, Zonas.tamano_celda(500))
  end

  test "maximo: lista vacía, un elemento y varios" do
    assert Zonas.maximo([]) == 0
    assert Zonas.maximo([5]) == 5
    assert Zonas.maximo([3, 7, 2]) == 7
  end

  test "metros en cero o negativos no se aceptan" do
    av = perro(1, 25.4123, -100.9876)

    assert_raise FunctionClauseError, fn -> Zonas.zonas([av], 0) end
    assert_raise FunctionClauseError, fn -> Zonas.zonas([av], -500) end
    assert_raise FunctionClauseError, fn -> Zonas.zonas([], 0) end
  end
end