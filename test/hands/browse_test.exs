defmodule Hands.BrowseTest do
  use Hands.DataCase
  alias Hands.Browse

  describe "seen_events" do
    alias Hands.Browse.SeenEvent
    import Hands.AccountsFixtures
    import Hands.BrowseFixtures

    setup do
      %{member_id: member_fixture().id}
    end

    test "create_seen_event!/2 with valid data creates a seen_event which is unique", %{member_id: member_id} do
      seen_member_id = member_fixture().id

      assert %SeenEvent{} = Browse.create_seen_event!(member_id, seen_member_id)
      assert_raise Ecto.ConstraintError, fn -> Browse.create_seen_event!(member_id, seen_member_id) end
    end

    test "create_seen_event!/2 with invalid ids raises error", %{member_id: member_id} do
      invalid_member_id = "deadbeef-dead-dead-dead-deaddeafbeef"

      assert_raise Ecto.ConstraintError, fn -> Browse.create_seen_event!(member_id, invalid_member_id) end
    end

    test "create_seen_event!/2 with duplicate ids data raises error", %{member_id: duplicate_member_id} do
      assert_raise FunctionClauseError, fn -> Browse.create_seen_event!(duplicate_member_id, duplicate_member_id) end
    end
  end

  describe "liked_events" do
    alias Hands.Browse.LikedEvent
    import Hands.AccountsFixtures
    import Hands.BrowseFixtures

    setup do
      %{member_id: member_fixture().id}
    end

    test "create_liked_event!/2 with valid data creates a liked_event which is unique", %{member_id: member_id} do
      liked_member_id = member_fixture().id

      assert %LikedEvent{} = Browse.create_liked_event!(member_id, liked_member_id)
      assert_raise Ecto.ConstraintError, fn -> Browse.create_liked_event!(member_id, liked_member_id) end
    end

    test "create_liked_event!/2 with invalid ids raises error", %{member_id: member_id} do
      invalid_member_id = "deadbeef-dead-dead-dead-deaddeafbeef"

      assert_raise Ecto.ConstraintError, fn -> Browse.create_liked_event!(member_id, invalid_member_id) end
    end

    test "create_liked_event!/2 with duplicate ids data raises error", %{member_id: duplicate_member_id} do
      assert_raise FunctionClauseError, fn -> Browse.create_liked_event!(duplicate_member_id, duplicate_member_id) end
    end
  end
end
