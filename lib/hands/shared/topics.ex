defmodule Hands.Shared.Topics do
  def member_topic(member_id) when is_binary(member_id) do
    "members:#{member_id}"
  end

  def room_topic(room_id) when is_binary(room_id) do
    "rooms:#{room_id}"
  end
end
