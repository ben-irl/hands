defmodule Hands.Browse.LikedEvent do
  use Ecto.Schema

  @primary_key false
  @foreign_key_type :binary_id
  schema "browse_liked_events" do
    field :member_id, :binary_id, primary_key: true
    field :liked_member_id, :binary_id, primary_key: true

    timestamps(type: :utc_datetime)
  end
end
