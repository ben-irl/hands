defmodule Hands.Chat.RoomRegistry do
  def child_spec(_opts) do
    Registry.child_spec(keys: :unique, name: __MODULE__)
  end

  @doc """
  Registry stores the process id of the room the member is chatting
  with their current match. The `room_id` is linked to the lifecycle of
  the process, so if the process ends (i.e. when the chat room is closed)
  the lookup key will automatically be removed.
  """
  def find_room(room_id) do
    case Registry.lookup(__MODULE__, room_id) do
      [{pid, _}] ->
        {:ok, pid}

      [] ->
        {:error, :not_found}
    end
  end
end
