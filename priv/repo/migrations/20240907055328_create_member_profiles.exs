defmodule Hands.Repo.Migrations.CreateMemberProfiles do
  use Ecto.Migration

  def change do
    create table(:accounts_member_profiles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :member_id, references(:accounts_members, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string
      add :age, :integer
      add :gender, :string
      add :want_genders, {:array, :string}
      add :want_age_start, :integer
      add :want_age_end, :integer
      add :is_ready, :boolean

      timestamps(type: :utc_datetime)
    end
  end
end
