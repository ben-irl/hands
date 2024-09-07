defmodule Hands.Repo.Migrations.CreateBrowseMatches do
  use Ecto.Migration

  def change do
    create table(:browse_matches, primary_key: false) do
      add :member_1_id, references(:accounts_members, type: :binary_id, on_delete: :delete_all), primary_key: true, null: false
      add :member_2_id, references(:accounts_members, type: :binary_id, on_delete: :delete_all), primary_key: true, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:browse_matches, [:member_1_id, :member_2_id])
  end
end
