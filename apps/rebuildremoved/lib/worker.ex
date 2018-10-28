defmodule Rebuildremoved.Worker do
  use GenServer
  require Logger
  require Gocd

  # GenServer init

  def start_link(job_config) do
    GenServer.start_link(__MODULE__, job_config, [])
  end

  def init(job_config) do
    schedule_next(1000)
    {:ok, job_config}
  end

  # GenServer callbacks

  def handle_info(:check, job_config) do
    check(job_config)
    {:noreply, job_config}
  end

  # implementation

  defp check(job_config) do
    Logger.info("Checking: #{inspect(job_config)}")
    Gocd.trigger_if_artifacts_missing(job_config)
    schedule_next()
  end

  # delay with max 10% random extra time
  defp schedule_next(delay_ms \\ delay()) do
    Process.send_after(self(), :check, round(delay_ms + 0.1 * :rand.uniform(delay_ms)))
  end

  defp delay(), do: delay(Application.get_env(:rebuildremoved, :delay_ms))
  defp delay(delay_ms) when is_binary(delay_ms), do: delay_ms |> String.to_integer()
  defp delay(delay_ms), do: delay_ms
end
