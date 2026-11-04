defmodule Perritos.ZonasRouter do
  @moduledoc """
  Cáscara HTTP de *Zonas de concentración*: lee la petición, trae los avistamientos,
  llama al núcleo (`Perritos.Zonas`) y responde JSON. Aquí no se calcula nada.
  """
  use Plug.Router

  plug :match
  plug :dispatch

  # GET /f/zonas?metros=500
  get "/" do
    conn = fetch_query_params(conn)
    metros = entero(conn.query_params["metros"], 500)

    case Perritos.Datos.avistamientos() do
      {:ok, avistamientos} ->
        responder(conn, 200, Perritos.Zonas.zonas(avistamientos, metros))

      {:error, _} ->
        responder(conn, 503, %{error: "no se pudieron obtener los avistamientos"})
    end
  end

  match _ do
    send_resp(conn, 404, "no encontrado")
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