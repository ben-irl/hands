defmodule Hands.Chat.RoomKeeperServer do
  use GenServer
  alias Hands.Chat.RoomKeeper

  # TODO: A `Flow` based system with back pressure instead of batches.

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    schedule_work()

    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    RoomKeeper.run()
    schedule_work()

    {:noreply, state}
  end

  defp schedule_work do
    Process.send_after(self(), :work, :timer.seconds(10))
  end
end
