defmodule Perritos.Router do
  @moduledoc "Cáscara HTTP: traduce peticiones en llamadas al núcleo."
  use Plug.Router

  plug :match
  plug :dispatch

  get "/f/salud" do
    send_resp(conn, 200, "ok")
  end

  # Ruta temporal para comprobar que llegan los datos; cada funcionalidad tendrá la suya.
  get "/f/avistamientos" do
    case Perritos.Datos.avistamientos() do
      {:ok, avistamientos} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(avistamientos))

      {:error, _} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(503, ~s({"error": "no se pudieron obtener los avistamientos"}))
    end
  end
  
  forward "/f/estadisticas", to: Perritos.EstadisticasRouter

  match _ do
    send_resp(conn, 404, "no encontrado")
  end
end