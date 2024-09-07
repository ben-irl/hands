defmodule HandsWeb.BrowseForm do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :reaction, Ecto.Enum, values: [:pass, :like]
    field :member_id, :binary_id
  end

  def new!(attrs) do
    attrs
    |> changeset()
    |> apply_action!(:inserted)
  end

  def changeset(attrs) do
    cast(%__MODULE__{}, attrs, [:reaction, :member_id])
  end
end
