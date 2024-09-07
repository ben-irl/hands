defmodule HandsWeb.MemberProfileLiveTest do
  use HandsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Hands.AccountsFixtures

  @create_attrs %{name: "some name", age: 42, gender: "some gender", want_genders: "some want_genders"}
  @update_attrs %{name: "some updated name", age: 43, gender: "some updated gender", want_genders: "some updated want_genders"}
  @invalid_attrs %{name: nil, age: nil, gender: nil, want_genders: nil}

  defp create_member_profile(_) do
    member_profile = member_profile_fixture()
    %{member_profile: member_profile}
  end

  describe "Index" do
    setup params do
      %{member_profile: member_profile} = create_member_profile("")
      %{conn: conn, member: member} = register_and_log_in_member(params)

      Map.merge(params, %{conn: conn, member: member, member_profile: member_profile})
    end

    test "lists all member_profiles", %{conn: conn, member_profile: member_profile} do
      {:ok, _index_live, html} = live(conn, ~p"/account/profile")

      assert html =~ "Listing Member profiles"
      assert html =~ member_profile.name
    end

    test "saves new member_profile", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/account/profile")

      assert index_live |> element("a", "New Member profile") |> render_click() =~
               "New Member profile"

      assert_patch(index_live, ~p"/account/profile/new")

      assert index_live
             |> form("#member_profile-form", member_profile: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#member_profile-form", member_profile: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/account/profile")

      html = render(index_live)
      assert html =~ "Member profile created successfully"
      assert html =~ "some name"
    end

    test "updates member_profile in listing", %{conn: conn, member_profile: member_profile} do
      {:ok, index_live, _html} = live(conn, ~p"/account/profile")

      assert index_live |> element("#member_profiles-#{member_profile.id} a", "Edit") |> render_click() =~
               "Edit Member profile"

      assert_patch(index_live, ~p"/account/profile/#{member_profile}/edit")

      assert index_live
             |> form("#member_profile-form", member_profile: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#member_profile-form", member_profile: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/account/profile")

      html = render(index_live)
      assert html =~ "Member profile updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes member_profile in listing", %{conn: conn, member_profile: member_profile} do
      {:ok, index_live, _html} = live(conn, ~p"/account/profile")

      assert index_live |> element("#member_profiles-#{member_profile.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#member_profiles-#{member_profile.id}")
    end
  end

  describe "Show" do
    setup params do
      %{member_profile: member_profile} = create_member_profile("")
      %{conn: conn, member: member} = register_and_log_in_member(params)

      Map.merge(params, %{conn: conn, member: member, member_profile: member_profile})
    end

    test "displays member_profile", %{conn: conn, member_profile: member_profile} do
      {:ok, _show_live, html} = live(conn, ~p"/account/profile/#{member_profile}")

      assert html =~ "Show Member profile"
      assert html =~ member_profile.name
    end

    test "updates member_profile within modal", %{conn: conn, member_profile: member_profile} do
      {:ok, show_live, _html} = live(conn, ~p"/account/profile/#{member_profile}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Member profile"

      assert_patch(show_live, ~p"/account/profile/#{member_profile}/show/edit")

      assert show_live
             |> form("#member_profile-form", member_profile: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#member_profile-form", member_profile: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/account/profile/#{member_profile}")

      html = render(show_live)
      assert html =~ "Member profile updated successfully"
      assert html =~ "some updated name"
    end
  end
end
