defmodule Hands.Browse.Match do
  use Ecto.Schema

  @primary_key false
  @foreign_key_type :binary_id
  schema "browse_matches" do
    field :member_1_id, :binary_id, primary_key: true
    field :member_2_id, :binary_id, primary_key: true

    timestamps(type: :utc_datetime)
  end
end
