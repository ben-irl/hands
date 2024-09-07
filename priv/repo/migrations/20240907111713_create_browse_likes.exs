defmodule Hands.Repo.Migrations.CreateBrowseLikes do
  use Ecto.Migration

  def change do
    create table(:browse_likes, primary_key: false) do
      add :member_id, references(:accounts_members, type: :binary_id, on_delete: :delete_all), primary_key: true, null: false
      add :liked_member_id, references(:accounts_members, type: :binary_id, on_delete: :delete_all), primary_key: true, null: false
      add :is_matched, :boolean, default: false

      timestamps(type: :utc_datetime)
    end
  end
end
