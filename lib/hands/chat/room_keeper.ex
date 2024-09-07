defmodule Hands.Chat.RoomKeeper do
  @moduledoc """
  This takes matches when both members are available it creates a chat
  room for them.
  """
  alias Hands.Chat.RoomRegistry
  alias Hands.Browse
  alias Hands.Chat.Events
  # alias Hands.Chat.MemberRegistry
  alias Hands.Chat.RoomDynamicSupervisor
  alias Hands.Chat.RoomRegistry
  alias Hands.Chat.Room
  alias Hands.Shared.Topics
  alias Hands.Repo
  import Ecto.Query, warn: false

  def run() do
    with {:ok, matches} <- fetch_matches() do
      matches
      |> Enum.filter(&members_available?/1)
      |> Enum.map(fn match ->
        room = to_room(match)

        # Only mark matches as used when a room has been joined by both
        # members or the chat room's time has run out.
        case RoomRegistry.find_room(room.id) do
          {:ok, _pid} ->
            broadcast_to_members!(room)

          {:error, :not_found} ->
            {:ok, _pid} = RoomDynamicSupervisor.prepare_room(room)
            broadcast_to_members!(room)
        end

        # mark_match_as_used(match.id)
      end)
    end
  end

  # defp mark_match_as_used(match_id) do
  #   query = from m in Browse.Match, where: m.id == ^match_id
  #   Repo.update_all(query, set: [is_used: true])
  # end

  def fetch_matches() do
    query = from m in Browse.Match, where: m.is_used != true

    case Repo.all(query) do
      [] ->
        {:error, :no_matches_found}

      matches ->
        {:ok, matches}
    end
  end

  # TODO: Implement MemberRegistry on RoomDynamicSupervisor init
  defp members_available?(%Browse.Match{}), do: true
  # defp members_available?(%Browse.Match{} = match) do
  #   %{member_1_id: member_1_id, member_2_id: member_2_id} = match

  #   match?({:error, :not_found}, MemberRegistry.find_member(member_1_id))
  #     and match?({:error, :not_found}, MemberRegistry.find_member(member_2_id))
  # end

  defp to_room(%Browse.Match{} = match) do
    %{
      id: id,
      member_1_id: member_1_id,
      member_2_id: member_2_id
    } = match

    %Room{
      id: id,
      member_1_id: member_1_id,
      member_2_id: member_2_id
    }
  end

  defp broadcast_to_members!(%Room{} = room) do
    %{
      id: room_id,
      member_1_id: member_1_id,
      member_2_id: member_2_id
    } = room

    event = %Events.RoomOpened{room_id: room_id, occured_at: DateTime.utc_now()}

    :ok = broadcast_to_member!(member_1_id, event)
    :ok = broadcast_to_member!(member_2_id, event)
  end

  defp broadcast_to_member!(member_id, event) do
    Phoenix.PubSub.broadcast!(Hands.PubSub, Topics.member_topic(member_id), event)
  end
end
