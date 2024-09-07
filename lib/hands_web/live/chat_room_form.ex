defmodule HandsWeb.ChatRoomForm do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :message, :string
  end

  def new!(attrs) do
    attrs
    |> changeset()
    |> apply_action!(:inserted)
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:message])
    |> validate_required([:message])
    |> validate_length(:message, min: 1, max: 100)
  end
end
