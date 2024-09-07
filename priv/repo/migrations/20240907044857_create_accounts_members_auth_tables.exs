defmodule Hands.Repo.Migrations.CreateAccountsMembersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:accounts_members, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:accounts_members, [:email])

    create table(:accounts_members_tokens) do
      add :member_id, references(:accounts_members, type: :binary_id, on_delete: :delete_all), null: false

      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:accounts_members_tokens, [:member_id])
    create unique_index(:accounts_members_tokens, [:context, :token])
  end
end
