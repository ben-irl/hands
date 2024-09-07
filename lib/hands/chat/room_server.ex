defmodule Hands.Chat.RoomServer do
  use GenServer
  alias Hands.Chat.RoomRegistry
  alias Hands.Chat.Room
  alias Hands.Chat.Events

  # API

  def start_link(room_id, opts) do
    GenServer.start_link(__MODULE__, opts, name: via(room_id))
  end

  def send_message(room_id, member_id, message) do
    GenServer.call(via(room_id), {:send_message, {member_id, message}})
  end

  # Callbacks

  @impl true
  def init(%Room{} = state) do
    # Chat room open
    # TODO: Move room opened event here
    # event = ""
    # {:ok, params, {:continue, {:broadcast, event}}}
    {:ok, state}
  end

  @impl true
  def handle_call({:send_message, {member_id, message}}, _from, %Room{} = state) do
    authorize!(state, member_id)

    %{id: room_id} = state

    event =
      %Events.MessageSent{
        room_id: room_id,
        message_id: Ecto.UUID.autogenerate(),
        member_id: member_id,
        message: message,
        occured_at: DateTime.utc_now()
      }

    # Most chat room updates will be recieved by all participants
    # via the pub sub topic they are subscribed to, so only return
    # `:ok` or `{:error, _reason}`.
    {:reply, _reply = :ok, state, {:continue, {:broadcast, event}}}
  end

  @impl true
  def handle_continue({:broadcast, event}, %Room{} = state) do
    %{id: room_id} = state

    Phoenix.PubSub.broadcast!(
      Hands.PubSub,
      Hands.Shared.Topics.room_topic(room_id),
      event)

    {:noreply, state}
  end

  # Helpers

  defp authorize!(%Room{} = room, member_id) do
    %{member_1_id: member_1_id, member_2_id: member_2_id} = room

    true = (member_id in [member_1_id, member_2_id])
  end

  defp via(room_id), do: {:via, Registry, {RoomRegistry, room_id}}
end
