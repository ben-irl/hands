defmodule Hands.Chat.RoomServer do
  use GenServer
  alias Hands.Chat.RoomRegistry

  # API

  def start_link(room_id, opts) do
    GenServer.start_link(__MODULE__, opts, name: via(room_id))
  end

  def do_something(room_id) do
    GenServer.call(via(room_id), {:do_something, %{}})
  end

  # Callbacks

  @impl true
  def init(params) do
    # Chat room open
    events = []
    {:ok, params, {:continue, {:broadcast, events}}}
  end

  @impl true
  def handle_call({:do_something, _payload}, _from, state) do
    events = []

    # Most chat room updates will be recieved by all participants
    # via the pub sub topic they are subscribed to, so only return
    # `:ok` or `{:error, _reason}`.
    reply = :ok

    {:reply, reply, state, {:continue, {:broadcast, events}}}
  end

  @impl true
  def handle_continue({:broadcast, _events}, state) do
    {:noreply, state}
  end

  # Helpers

  defp via(room_id), do: {:via, Registry, {RoomRegistry, room_id}}
end
