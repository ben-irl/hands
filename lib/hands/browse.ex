defmodule Hands.Browse do
  @moduledoc """
  The Browse context.
  """
  alias Hands.Browse.LikedEvent
  alias Hands.Browse.SeenEvent
  alias Hands.Repo
  import Ecto.Query, warn: false

  @doc """
  Creates a seen_event.

  ## Examples

      iex> create_seen_event!(member_id, seen_member_id)
      %SeenEvent{}

  """
  def create_seen_event!(member_id, seen_member_id) when member_id != seen_member_id do
    Repo.insert!(%SeenEvent{member_id: member_id, seen_member_id: seen_member_id})
  end

  @doc """
  Creates a liked_event.

  ## Examples

      iex> create_liked_event!(member_id, liked_member_id)
      %LikedEvent{}

  """
  def create_liked_event!(member_id, liked_member_id) when member_id != liked_member_id do
    Repo.insert!(%LikedEvent{member_id: member_id, liked_member_id: liked_member_id})
  end
end
