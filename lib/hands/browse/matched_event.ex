defmodule Hands.Browse.MatchedEvent do
  use Ecto.Schema

  @primary_key false
  @foreign_key_type :binary_id
  schema "browse_matched_events" do
    field :member_id, :binary_id, primary_key: true
    field :seen_member_id, :binary_id, primary_key: true

    timestamps(type: :utc_datetime)
  end
end
