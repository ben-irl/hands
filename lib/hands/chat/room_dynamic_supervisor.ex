defmodule Hands.Chat.RoomDynamicSupervisor do
  use DynamicSupervisor
  alias Hands.Chat.RoomServer
  alias Hands.Chat.Room

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def prepare_room(%Room{id: room_id} = room) do
    child_spec = %{
      id: RoomServer,
      start: {RoomServer, :start_link, [room_id, room]},
      restart: :transient
    }
    {:ok, _pid} = DynamicSupervisor.start_child(__MODULE__, child_spec)
  end
end
