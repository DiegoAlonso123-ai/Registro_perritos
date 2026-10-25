defmodule Perritos.Datos do
  @moduledoc """
  Cáscara: lee los avistamientos del backend del Proyecto 1 (opción B)
  y los convierte en structs para el núcleo.
  """
  alias Perritos.Avistamiento

  def avistamientos do
    case Req.get(System.fetch_env!("BACKEND_URL") <> "/api/avistamientos") do
      {:ok, %Req.Response{status: 200, body: lista}} when is_list(lista) ->
        {:ok, Enum.map(lista, &a_avistamiento/1)}

      {:ok, %Req.Response{status: status}} ->
        {:error, {:status, status}}

      {:error, error} ->
        {:error, error}
    end
  end

  # Req ya decodificó el JSON: son mapas con llaves de texto.
  # Los colores se dejan como texto, porque el catálogo trae nombres como "Manchado (blanco y negro)".
  defp a_avistamiento(m) do
    %Avistamiento{
      id: m["id"],
      nombre: m["nombre"],
      raza: m["raza"],
      colores: m["colores"],
      lat: m["lat"],
      lon: m["lon"],
      foto: m["foto"],
      fecha: NaiveDateTime.from_iso8601!(m["fecha"])
    }
  end
end