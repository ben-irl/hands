defmodule Hands.Chat.Events.MemberLeft do
  @moduledoc """
  This is a temporary situation, it means the memeber is not
  looking at the chat screen. They may return
  """
  defstruct [:room_id, :member_id, :occured_at]
end
