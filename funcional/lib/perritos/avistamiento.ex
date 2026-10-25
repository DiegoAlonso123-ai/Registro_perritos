defmodule Perritos.Avistamiento do
  @moduledoc "Un avistamiento de un perrito. Solo datos, sin lógica."

  @derive {Jason.Encoder, only: [:id, :nombre, :raza, :colores, :lat, :lon, :foto, :fecha]}
  defstruct [:id, :nombre, :raza, :colores, :lat, :lon, :foto, :fecha]
end