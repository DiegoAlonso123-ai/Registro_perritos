defmodule Perritos.MixProject do
  use Mix.Project

  def project do
    [
      app: :funcional,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Perritos.Application, []}
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.16"},
      {:bandit, "~> 1.5"},
      {:jason, "~> 1.4"},
      {:req, "~> 0.5"}
    ]
  end

  # Las pruebas del núcleo no arrancan la aplicación (así no buscan servidor ni red)
  defp aliases do
    [test: "test --no-start"]
  end
end