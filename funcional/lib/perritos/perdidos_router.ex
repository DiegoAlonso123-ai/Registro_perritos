defmodule Perritos.PerdidosRouter do
  @moduledoc """
  Cáscara HTTP de *Perros perdidos de vista*: lee la petición, trae los avistamientos,
  lee el reloj, llama al núcleo (`Perritos.Perdidos`) y responde JSON.
  Aquí no se calcula nada: los efectos (reloj, red, respuesta) viven en la cáscara.
  """
  use Plug.Router

  plug :match
  plug :dispatch

  # GET /f/perdidos?dias=14
  get "/" do
    conn = fetch_query_params(conn)
    dias = entero(conn.query_params["dias"], 14)
    # efecto: leer el reloj. Por eso se hace aquí y el núcleo recibe "ahora" como argumento
    ahora = NaiveDateTime.local_now()

    case Perritos.Datos.avistamientos() do
      {:ok, avistamientos} ->
        zonas = Perritos.Perdidos.perdidos(avistamientos, dias, ahora)
        responder(conn, 200, %{dias: dias, zonas: zonas})

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