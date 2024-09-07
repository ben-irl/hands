defmodule HandsWeb.MemberRegistrationLiveTest do
  use HandsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Hands.AccountsFixtures

  describe "Registration page" do
    test "renders registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/account/register")

      assert html =~ "Register"
      assert html =~ "Log in"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_member(member_fixture())
        |> live(~p"/account/register")
        |> follow_redirect(conn, "/browse")

      assert {:ok, _conn} = result
    end

    test "renders errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/account/register")

      result =
        lv
        |> element("#registration_form")
        |> render_change(member: %{"email" => "with spaces", "password" => "too short"})

      assert result =~ "Register"
      assert result =~ "must have the @ sign and no spaces"
      assert result =~ "should be at least 12 character"
    end
  end

  describe "register member" do
    test "creates account and logs the member in", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/account/register")

      email = unique_member_email()
      form = form(lv, "#registration_form", member: valid_member_attributes(email: email))
      render_submit(form)
      conn = follow_trigger_action(form, conn)

      assert redirected_to(conn) == ~p"/browse"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/browse")
      response = html_response(conn, 200)
      assert response =~ email
      assert response =~ "Settings"
      assert response =~ "Log out"
    end

    test "renders errors for duplicated email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/account/register")

      member = member_fixture(%{email: "test@email.com"})

      result =
        lv
        |> form("#registration_form",
          member: %{"email" => member.email, "password" => "valid_password"}
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end
  end

  describe "registration navigation" do
    test "redirects to login page when the Log in button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/account/register")

      {:ok, _login_live, login_html} =
        lv
        |> element(~s|main a:fl-contains("Log in")|)
        |> render_click()
        |> follow_redirect(conn, ~p"/account/log_in")

      assert login_html =~ "Log in"
    end
  end
end
