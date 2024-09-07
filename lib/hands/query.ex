defmodule Hands.Query do
  alias Hands.Accounts
  alias Hands.Browse
  alias Hands.Repo
  import Ecto.Query, warn: false

  def fetch_next_unseen_profile(member_id) do
    query =
      from mp in Accounts.MemberProfile,
        left_join: se in Browse.Seen,
          on: se.member_id == ^member_id and mp.member_id == se.seen_member_id,
        where: is_nil(se.member_id),
        where: mp.member_id != ^member_id,
        select: mp,
        limit: 1

    case Repo.one(query) do
      nil ->
        {:error, :no_unseen_profiles}

      profile ->
        {:ok, profile}
    end
  end
end
