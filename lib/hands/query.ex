defmodule Hands.Query do
  alias Hands.Accounts
  alias Hands.Browse
  alias Hands.Repo
  import Ecto.Query, warn: false

  def fetch_next_unseen_profile(member_id) do
    query =
      from mp in Accounts.MemberProfile,
        left_join: se in Browse.SeenEvent,
          on: se.member_id == ^member_id and mp.member_id == se.seen_member_id,
        where: is_nil(se.member_id),
        select: mp,
        limit: 1

    case Repo.one(query) do
      nil ->
        {:error, :no_unseen_profiles}

      profile ->
        {:ok, profile}
    end
  end

  def fetch_next_500_mutual_likes() do
    query =
      from e1 in Browse.LikedEvent,
        join: e2 in Browse.LikedEvent,
          on: e1.member_id == e2.seen_member_id,
        where: e2.member_id == e1.seen_member_id,
        select: %Browser.Mutual{members: [e1.member_id, e2.member_id]},
        limit: 500

    case Repo.all(query) do
      nil ->
        {:error, :no_mutual_likes}

      matches ->
        {:ok, matches}
    end
  end
end
