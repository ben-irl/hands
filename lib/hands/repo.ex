defmodule Hands.Repo do
  use Ecto.Repo,
    otp_app: :hands,
    adapter: Ecto.Adapters.Postgres
end
