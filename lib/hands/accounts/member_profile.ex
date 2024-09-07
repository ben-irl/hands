defmodule Hands.Accounts.MemberProfile do
  use Ecto.Schema
  alias Hands.Accounts.Member
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "member_profiles" do
    belongs_to :member, Member

    field :name, :string
    field :age, :integer
    field :gender, :string
    field :want_genders, :string
    field :is_ready, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(member_profile, attrs) do
    member_profile
    |> cast(attrs, [:name, :age, :gender, :want_genders])
    |> validate_required([:name, :age, :gender, :want_genders])
    |> put_change(:is_ready, true)
  end

  def put_member(changeset, %Member{} = member) do
    changeset
    |> put_assoc(:member, member)
  end
end
