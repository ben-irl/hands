defmodule Hands.Chat.Events.MessageSent do
  defstruct [:room_id, :message_id, :member_id, :message, :occured_at]
end
