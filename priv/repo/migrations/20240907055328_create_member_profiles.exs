defmodule Hands.Repo.Migrations.CreateMemberProfiles do
  use Ecto.Migration

  def change do
    create table(:member_profiles) do
      add :name, :string
      add :age, :integer
      add :gender, :string
      add :want_genders, :string

      timestamps(type: :utc_datetime)
    end
  end
end
