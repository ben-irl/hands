defmodule Hands.Browse.Matchmaker do
  alias Hands.Browse.Like
  alias Hands.Browse.Match
  alias Hands.Repo
  import Ecto.Query, warn: false

  # NOTE: It's 02:18 in the morning, my mind has gone missing!
  def run() do
    # TODO: More efficient matching+availability checking.
    # TODO: Add resource pool for chatrooms.
    fetch_mutual_liker()
    |> Enum.chunk_every(10)
    |> Enum.each(fn mutual_likes ->
      bulk_mark_likes_as_matched(mutual_likes)
      bulk_create_matches(mutual_likes)
    end)
  end

  defp fetch_mutual_liker() do
    # TODO: More efficient data structures
    query =
      from e1 in Like,
        join: e2 in Like,
          on: e1.member_id == e2.liked_member_id,
        where: e2.member_id == e1.liked_member_id,
        where: e1.is_matched != true,
        where: e2.is_matched != true,
        select: [e1.member_id, e2.member_id],
        limit: 500

    Repo.all(query)
  end

  defp bulk_mark_likes_as_matched(mutual_likes) do
    mutual_ids =
        mutual_likes
        |> Enum.reduce([], fn [m1, m2], acc -> [m1, m2 | acc] end)
        |> Enum.uniq()

      like_matched_query =
        from l in Like,
          where: l.member_id in ^mutual_ids,
          or_where: l.liked_member_id in ^mutual_ids

    Repo.update_all(like_matched_query, set: [is_matched: true])
  end

  defp bulk_create_matches(mutual_likes) do
    matches =
      mutual_likes
      |> Enum.map(fn [_, _ ] = mutual_like ->
        [member_1_id, member_2_id] = Enum.sort(mutual_like)

        %{
          id: Ecto.UUID.autogenerate(),
          member_1_id: member_1_id,
          member_2_id: member_2_id,
          inserted_at: {:placeholder, :inserted_at},
          updated_at: {:placeholder, :inserted_at}
        }
      end)

    placeholders = %{inserted_at: DateTime.truncate(DateTime.utc_now(), :second)}

    Repo.insert_all(Match, matches, [
      on_conflict: :nothing,
      placeholders: placeholders
    ])
  end
end
