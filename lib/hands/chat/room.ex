defmodule Hands.Chat.Room do
  @moduledoc """
  State of RoomServer.
  """
  defstruct [:id, :member_1_id, :member_2_id, messages: []]
end
