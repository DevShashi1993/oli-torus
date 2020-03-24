defmodule Oli.NavigationTest do
  use OliWeb.ConnCase

  test "shows a sign out link when signed in", %{conn: conn} do
    author = author_fixture()

    conn = conn
    |> assign(:current_author, author)
    |> get("/")

    assert html_response(conn, 200) =~ "Sign out"
  end
end