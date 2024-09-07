defmodule HandsWeb.PageControllerTest do
  use HandsWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Register"
    assert html_response(conn, 200) =~ "Log-in"
  end
end
