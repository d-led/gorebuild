defmodule Rebuildremoved.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    Logger.info "starting..."

    children = 1..3 |> Enum.map(fn id ->
      Supervisor.child_spec(Rebuildremoved.Worker, id: String.to_atom("worker#{id}"))
    end)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Rebuildremoved.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
