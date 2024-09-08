defmodule Hands.Chat.RoomServer do
  use GenServer
  alias Hands.Chat.RoomKeeper
  alias Hands.Chat.RoomRegistry
  alias Hands.Chat.Room
  alias Hands.Chat.Events

  # TODO: Store events in memory (persist on room shutdown).

  # API

  def start_link(room_id, opts) do
    GenServer.start_link(__MODULE__, opts, name: via(room_id))
  end

  def fetch_rem_seconds!(room_id) do
    GenServer.call(via(room_id), :fetch_rem_seconds!)
  end

  def send_message(room_id, member_id, message) do
    GenServer.call(via(room_id), {:send_message, {member_id, message}})
  end

  def notify_joined(room_id, member_id) do
    GenServer.call(via(room_id), {:notify_joined, member_id})
  end

  def notify_left(room_id, member_id) do
    GenServer.call(via(room_id), {:notify_left, member_id})
  end

  # Callbacks

  @impl true
  def init(%Room{} = state) do
    # Chat room open
    # TODO: Move room opened event here
    # event = ""
    # {:ok, params, {:continue, {:broadcast, event}}}

    state = %{state | closes_at: DateTime.utc_now() |> DateTime.add(10, :minute)}
    Process.send_after(self(), :close_room, :timer.minutes(10))

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

  def handle_call(:fetch_rem_seconds!, _from, %Room{} = state) do
    %{id: _room_id, closes_at: closes_at} = state

    rem_seconds = DateTime.diff(closes_at, DateTime.utc_now(), :second)

    {:reply, rem_seconds, state}
  end

  def handle_call({:notify_joined, member_id}, _from, %Room{} = state) do
    authorize!(state, member_id)

    %{id: room_id} = state

    event =
      %Events.MemberJoined{
        room_id: room_id,
        member_id: member_id,
        occured_at: DateTime.utc_now()
      }

    # Most chat room updates will be recieved by all participants
    # via the pub sub topic they are subscribed to, so only return
    # `:ok` or `{:error, _reason}`.
    {:reply, _reply = :ok, state, {:continue, {:broadcast, event}}}
  end

  def handle_call({:notify_left, member_id}, _from, %Room{} = state) do
    authorize!(state, member_id)

    %{id: room_id} = state

    event =
      %Events.MemberLeft{
        room_id: room_id,
        member_id: member_id,
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

  @impl true
  def handle_info(:close_room, %Room{} = state) do
    %{id: room_id} = state

    event = %Events.RoomClosed{room_id: room_id, occured_at: DateTime.utc_now()}

    Phoenix.PubSub.broadcast!(
      Hands.PubSub,
      Hands.Shared.Topics.room_topic(room_id),
      event)

    {:stop, :close_room, state}
  end

  @impl true
  def terminate(:close_room, %Room{} = state) do
    # Perform cleanup tasks here
    RoomKeeper.mark_match_as_used(state.id)
    :ok
  end

  # Helpers

  defp authorize!(%Room{} = room, member_id) do
    %{member_1_id: member_1_id, member_2_id: member_2_id} = room

    true = (member_id in [member_1_id, member_2_id])
  end

  defp via(room_id), do: {:via, Registry, {RoomRegistry, room_id}}
end
