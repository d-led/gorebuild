defmodule Rebuildremoved.Supervisor do
  @moduledoc false

  use DynamicSupervisor
  require Logger

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  # starting the supervisor and showing some output for early feedback
  def init(:ok) do
    Gocd.start()

    Logger.warn("Delay #{Application.get_env(:rebuildremoved, :delay_ms)}ms + random(10%)")

    DynamicSupervisor.init(strategy: :one_for_one)
  end

  # starting a supervised polling process for each line of config
  def start_children do
    Application.get_env(:rebuildremoved, :artifacts)
    |> Enum.with_index()
    |> Enum.map(fn {job_config, id} ->
      spec =
        Supervisor.child_spec(
          {Rebuildremoved.Worker, job_config},
          id: String.to_atom("worker#{id}"),
          restart: :transient
        )

      {:ok, _pid} = DynamicSupervisor.start_child(__MODULE__, spec)
    end)
  end
end

defmodule Rebuildremoved.Application do
  @moduledoc false

  use Application

  #
  def start(_type, _args) do
    children = [
      Rebuildremoved.Supervisor
    ]

    opts = [strategy: :one_for_one, name: Rebuildremoved.App]
    ret = Supervisor.start_link(children, opts)

    Rebuildremoved.Supervisor.start_children()

    ret
  end
end
