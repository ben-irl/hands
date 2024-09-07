defmodule Hands.Browse do
  @moduledoc """
  The Browse context.
  """
  alias Hands.Browse.Like
  alias Hands.Browse.Seen
  alias Hands.Browse.Match
  alias Hands.Repo
  import Ecto.Query, warn: false

  @doc """
  Creates a seen_event.

  ## Examples

      iex> create_seen!(member_id, seen_member_id)
      %Seen{}

  """
  def create_seen!(member_id, seen_member_id) when member_id != seen_member_id do
    Repo.insert!(%Seen{member_id: member_id, seen_member_id: seen_member_id})
  end

  @doc """
  Creates a liked_event.

  ## Examples

      iex> create_like!(member_id, liked_member_id)
      %Like{}

  """
  def create_like!(member_id, liked_member_id) when member_id != liked_member_id do
    Repo.insert!(%Like{member_id: member_id, liked_member_id: liked_member_id})
  end

  def likes_marked_matched?(member_id, liked_member_id) do
    query =
      from l in Like,
        where: l.member_id == ^member_id,
        where: l.liked_member_id == ^liked_member_id

    Repo.exists?(query)
  end

  def fetch_matches!() do
    Repo.all(Match)
  end

  def matched?(member_ids) when is_list(member_ids) do
    [member_1_id, member_2_id] = Enum.sort(member_ids)

    query =
      from m in Match,
        where: m.member_1_id == ^member_1_id,
        where: m.member_2_id == ^member_2_id

    Repo.exists?(query)
  end
end
