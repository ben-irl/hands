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
      matches_attrs = bulk_create_matches(mutual_likes)
      bulk_mark_likes_as_matched(matches_attrs)
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

  defp bulk_create_matches(mutual_likes) do
    matches_attrs =
      mutual_likes
      |> Enum.map(fn [_, _ ] = mutual_like ->
        [member_1_id, member_2_id] = Enum.sort(mutual_like)

        %{
          member_1_id: member_1_id,
          member_2_id: member_2_id,
          inserted_at: {:placeholder, :inserted_at},
          updated_at: {:placeholder, :inserted_at}
        }
      end)

    placeholders = %{inserted_at: DateTime.truncate(DateTime.utc_now(), :second)}

    Repo.insert_all(Match, matches_attrs, [
      on_conflict: :nothing,
      placeholders: placeholders
    ])

    matches_attrs
  end

  defp bulk_mark_likes_as_matched([]), do: []
  defp bulk_mark_likes_as_matched(matches_attrs) when is_list(matches_attrs) do
    # TODO: Refactor!
    # Must be at least one where query or this will set everything to matched!
    [%{member_1_id: member_1_id, member_2_id: member_2_id} | rem_match_attrs] = matches_attrs

    init_query =
      from l in Like,
        where: l.member_id == ^member_1_id and l.liked_member_id == ^member_2_id,
        or_where: l.member_id == ^member_2_id and l.liked_member_id == ^member_1_id

    query =
      rem_match_attrs
      |> Enum.reduce(init_query, fn
        %{member_1_id: member_1_id, member_2_id: member_2_id}, query ->
          from l in query,
            or_where: l.member_id == ^member_1_id and l.liked_member_id == ^member_2_id,
            or_where: l.member_id == ^member_2_id and l.liked_member_id == ^member_1_id
      end)

    Repo.update_all(query, set: [is_matched: true])
  end

end
