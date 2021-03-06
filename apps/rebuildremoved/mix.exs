defmodule Rebuildremoved.Mixfile do
  use Mix.Project

  def project do
    [
      app: :rebuildremoved,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Rebuildremoved.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, " ~> 1.2.0"},
      {:poison, ">= 3.1.0"},
      {:dialyxir, " >= 1.0.0-rc.2", only: [:dev], runtime: false}
    ]
  end

  # do not start the application during the test
  defp aliases do
    [
      test: "test --no-start"
    ]
  end
end
