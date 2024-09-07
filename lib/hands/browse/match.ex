defmodule Hands.Browse.Match do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "browse_matches" do
    field :member_1_id, :binary_id
    field :member_2_id, :binary_id
    field :is_used, :boolean, default: false

    timestamps(type: :utc_datetime)
  end
end
