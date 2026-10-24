defmodule Perritos.Application do
  @moduledoc "Arranca el servidor HTTP."
  use Application

  @impl true
  def start(_tipo, _args) do
    hijos = [
      {Bandit, plug: Perritos.Router, port: 4000}
    ]

    Supervisor.start_link(hijos, strategy: :one_for_one, name: Perritos.Supervisor)
  end
end