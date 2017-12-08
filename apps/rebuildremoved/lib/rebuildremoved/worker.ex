defmodule Rebuildremoved.Worker do
  use GenServer
  require Logger
  require Gocd

  @delay_ms Application.get_env(:rebuildremoved, :delay_ms) || 30*1000

  # GenServer init

  def start_link(job_config) do
    GenServer.start_link(__MODULE__, job_config, [])
  end

  def init(job_config) do
    check(job_config)
    schedule_next()
    {:ok, job_config}
  end

  # GenServer callbacks

  def handle_info(:check, job_config) do
   check(job_config)
   {:noreply, job_config}   
  end

  # implementation

  defp check(job_config) do
    Logger.info "Checking: #{inspect(job_config)}"
    Gocd.trigger_if_artifacts_missing(job_config)
    schedule_next()
  end

  defp schedule_next, do: Process.send_after(self(), :check, @delay_ms)
end
