defmodule Hands.Chat.Events.MessageSeen do
  defstruct [:room_id, :message_id, :occured_at]
end
