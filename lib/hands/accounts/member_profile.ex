defmodule Hands.Accounts.MemberProfile do
  use Ecto.Schema
  alias Hands.Accounts.Member
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounts_member_profiles" do
    belongs_to :member, Member

    field :name, :string
    field :age, :integer
    field :gender, Ecto.Enum, values: [:woman, :man, :non_binary]
    field :want_genders, {:array, :string}
    field :want_age_start, :integer, default: 19
    field :want_age_end, :integer, default: 120
    field :is_ready, :boolean, default: false

    # Placeholder for photo upload
    # field :photo_url, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(member_profile, attrs) do
    member_profile
    |> cast(attrs, [:name, :age, :gender, :want_genders, :want_age_start, :want_age_end])
    |> validate_required([:name, :age, :gender, :want_genders])
    |> validate_number(:age, greater_than_or_equal_to: 19)
    |> validate_subset(:want_genders, ["woman", "man", "non_binary"])
    |> validate_number(:want_age_start, greater_than_or_equal_to: 19, less_than_or_equal_to: 120)
    |> validate_number(:want_age_end, less_than_or_equal_to: 120)
    |> validate_want_age_range()
    |> put_change(:is_ready, true)
  end

  def validate_want_age_range(changeset) do
    want_age_start = fetch_field!(changeset, :want_age_start)
    want_age_end = fetch_field!(changeset, :want_age_end)

    if want_age_start > want_age_end do
      changeset
      |> add_error(:want_age_start, "Must be less than the maximum age")
    else
      changeset
    end
  end

  def put_member(changeset, %Member{} = member) do
    changeset
    |> put_assoc(:member, member)
  end
end
