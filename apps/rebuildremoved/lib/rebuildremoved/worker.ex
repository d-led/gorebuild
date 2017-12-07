defmodule Rebuildremoved.Worker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def init(_) do
    schedule()
    {:ok, 1}
  end

  def handle_info(:ping, state) do
    IO.puts "#{inspect(self())}: #{state}"
    schedule()
    {:noreply, state+1}
  end

  defp schedule, do: Process.send_after(self(), :ping, 1000)
end