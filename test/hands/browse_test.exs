defmodule Hands.BrowseTest do
  use Hands.DataCase
  alias Hands.Browse

  describe "seens" do
    alias Hands.Browse.Seen
    import Hands.AccountsFixtures
    import Hands.BrowseFixtures

    setup do
      %{member_id: member_fixture().id}
    end

    test "create_seen!/2 with valid data creates a seen_event which is unique", %{member_id: member_id} do
      seen_member_id = member_fixture().id

      assert %Seen{} = Browse.create_seen!(member_id, seen_member_id)
      assert_raise Ecto.ConstraintError, fn -> Browse.create_seen!(member_id, seen_member_id) end
    end

    test "create_seen!/2 with invalid ids raises error", %{member_id: member_id} do
      invalid_member_id = "deadbeef-dead-dead-dead-deaddeafbeef"

      assert_raise Ecto.ConstraintError, fn -> Browse.create_seen!(member_id, invalid_member_id) end
    end

    test "create_seen!/2 with duplicate ids data raises error", %{member_id: duplicate_member_id} do
      assert_raise FunctionClauseError, fn -> Browse.create_seen!(duplicate_member_id, duplicate_member_id) end
    end
  end

  describe "likes" do
    alias Hands.Browse.Like
    import Hands.AccountsFixtures
    import Hands.BrowseFixtures

    setup do
      %{member_id: member_fixture().id}
    end

    test "create_like!/2 with valid data creates a liked_event which is unique", %{member_id: member_id} do
      liked_member_id = member_fixture().id

      assert %Like{} = Browse.create_like!(member_id, liked_member_id)
      assert_raise Ecto.ConstraintError, fn -> Browse.create_like!(member_id, liked_member_id) end
    end

    test "create_like!/2 with invalid ids raises error", %{member_id: member_id} do
      invalid_member_id = "deadbeef-dead-dead-dead-deaddeafbeef"

      assert_raise Ecto.ConstraintError, fn -> Browse.create_like!(member_id, invalid_member_id) end
    end

    test "create_like!/2 with duplicate ids data raises error", %{member_id: duplicate_member_id} do
      assert_raise FunctionClauseError, fn -> Browse.create_like!(duplicate_member_id, duplicate_member_id) end
    end
  end

  describe "matchmaker" do
    alias Hands.Browse
    alias Hands.Browse.Matchmaker
    alias Hands.Browse.Like
    import Hands.AccountsFixtures
    import Hands.BrowseFixtures

    test "run/0 creates a match from mutual likes and marks likes as matched" do
      member_1_id = member_fixture().id
      member_2_id = member_fixture().id

      like_1 = Browse.create_like!(member_1_id, member_2_id)
      like_2 = Browse.create_like!(member_2_id, member_1_id)

      Matchmaker.run()

      assert Browse.likes_marked_matched?(like_1.member_id, like_1.liked_member_id)
      assert Browse.likes_marked_matched?(like_2.member_id, like_2.liked_member_id)
      assert Browse.matched?([member_1_id, member_2_id])
    end
  end
end
