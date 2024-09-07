defmodule Hands.Browse.Like do
  use Ecto.Schema

  @primary_key false
  @foreign_key_type :binary_id
  schema "browse_likes" do
    field :member_id, :binary_id, primary_key: true
    field :liked_member_id, :binary_id, primary_key: true
    field :is_matched, :boolean, default: false

    timestamps(type: :utc_datetime)
  end
end
