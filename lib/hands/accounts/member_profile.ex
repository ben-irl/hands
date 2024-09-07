defmodule Hands.Accounts.MemberProfile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "member_profiles" do
    field :name, :string
    field :age, :integer
    field :gender, :string
    field :want_genders, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(member_profile, attrs) do
    member_profile
    |> cast(attrs, [:name, :age, :gender, :want_genders])
    |> validate_required([:name, :age, :gender, :want_genders])
  end
end
