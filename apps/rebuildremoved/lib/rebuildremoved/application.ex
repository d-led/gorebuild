defmodule Rebuildremoved.Supervisor do
  @moduledoc false

  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    Logger.info "starting..."

    children = Application.get_env(:rebuildremoved, :artifacts)
      |> Enum.with_index
      |> Enum.map(fn {job_config, id} ->
        Supervisor.child_spec({Rebuildremoved.Worker, job_config}, id: String.to_atom("worker#{id}"), restart: :transient)
      end)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Rebuildremoved.Supervisor]

    Supervisor.init(children, opts)
  end
end

defmodule Rebuildremoved.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do

    children = [
      Rebuildremoved.Supervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Rebuildremoved.App]
    Supervisor.start_link(children, opts)
  end
end
