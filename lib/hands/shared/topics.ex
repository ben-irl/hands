defmodule Hands.Shared.Topics do
  def member_topic(member_id) when is_binary(member_id) do
    "members:#{member_id}"
  end
end
