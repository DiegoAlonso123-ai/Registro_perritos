defmodule Perritos.EstadisticasRouter do
  @moduledoc """
  Cáscara HTTP de *Estadísticas*: lee la petición, trae los avistamientos,
  llama al núcleo (`Perritos.Estadisticas`) y responde JSON. Aquí no se calcula nada.
  """
  use Plug.Router

  plug :match
  plug :dispatch

  # GET /f/estadisticas?n=5
  get "/" do
    conn = fetch_query_params(conn)
    n = entero(conn.query_params["n"], 5)

    case Perritos.Datos.avistamientos() do
      {:ok, avistamientos} ->
        cuerpo =
          avistamientos
          |> Perritos.Estadisticas.resumen(n)
          |> a_respuesta()

        responder(conn, 200, cuerpo)

      {:error, _} ->
        responder(conn, 503, %{error: "no se pudieron obtener los avistamientos"})
    end
  end

  match _ do
    send_resp(conn, 404, "no encontrado")
  end

  defp a_respuesta(resumen) do
    %{
      total: resumen.total,
      por_color: a_mapas(resumen.por_color),
      por_raza: a_mapas(resumen.por_raza),
      por_dia: a_mapas(resumen.por_dia),
      mas_comunes: %{
        colores: a_mapas(resumen.mas_comunes_colores),
        razas: a_mapas(resumen.mas_comunes_razas)
      }
    }
  end

  # Las tuplas no existen en JSON: se convierten en mapas justo antes de responder.
  defp a_mapas(conteos) do
    Enum.map(conteos, fn {nombre, cantidad} -> %{nombre: nombre, cantidad: cantidad} end)
  end

  defp responder(conn, estado, cuerpo) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(estado, Jason.encode!(cuerpo))
  end

  defp entero(texto, defecto) when is_binary(texto) do
    case Integer.parse(texto) do
      {n, ""} when n > 0 -> n
      _ -> defecto
    end
  end

  defp entero(_texto, defecto), do: defecto
end