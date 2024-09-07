defmodule Hands.Repo.Migrations.CreateBrowseSeens do
  use Ecto.Migration

  def change do
    create table(:browse_seens, primary_key: false) do
      add :member_id, references(:accounts_members, type: :binary_id, on_delete: :delete_all), primary_key: true, null: false
      add :seen_member_id, references(:accounts_members, type: :binary_id, on_delete: :delete_all), primary_key: true, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
