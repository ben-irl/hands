defmodule HandsWeb.ChatRoomMessage do
  defstruct [:id, :member_id, :message, :occured_at]

  def new!(member_id, message, occured_at \\ DateTime.utc_now()) do
    %__MODULE__{id: Ecto.UUID.autogenerate(),
      member_id: member_id,
      message: message,
      occured_at: occured_at}
  end
end
