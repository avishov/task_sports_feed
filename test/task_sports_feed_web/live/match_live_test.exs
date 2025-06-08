defmodule TaskSportsFeedWeb.MatchLiveTest do
  use TaskSportsFeedWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  import Mox

  describe "TaskSportsFeedWeb.MatchLiveTest" do
    test "displays the main page", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")
      assert html =~ "Live Match Status"
    end

    test "renders updated status when new data arrives", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      refute render(view) =~ "Atletico Madrid vs Sevilla"

      send(
        view.pid,
        {:status_update, %{match_id: 10, name: "Atletico Madrid vs Sevilla", status: "completed"}}
      )

      :timer.sleep(50)

      assert render(view) =~ "Atletico Madrid vs Sevilla"
    end

    test "clicking the button on the page disables the button", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, "/")

      assert view
             |> element("button#start_updates")
             |> then(fn elem ->
               :timer.sleep(50)
               elem
             end)
             |> render_click() =~
               "<button phx-click=\"start_updates\" disabled=\"disabled\" type=\"button\" id=\"start_updates\" class=\"focus:outline-none text-white bg-green-700 hover:bg-green-800 focus:ring-4 focus:ring-green-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-green-600 dark:hover:bg-green-700 dark:focus:ring-green-800 cursor-not-allowed\">"
    end

    test "clicking the button on the page starts the match updates", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, "/")

      assert view
             |> element("button#start_updates")
             |> then(fn elem ->
               :timer.sleep(50)
               elem
             end)
             |> render_click() =~
               "cursor-not-allowed"

      match_ids = [
        23_498_773,
        23_498_857,
        23_499_115,
        23_499_158,
        23_499_324,
        23_499_384,
        23_499_526,
        23_499_588,
        23_499_706,
        23_499_720
      ]

      assert Enum.any?(match_ids, fn match_id ->
               {:via, Registry, {TaskSportsFeed.MatchRegistry, match_id}}
               |> GenServer.whereis()
               |> is_pid()
             end)
    end
  end

  describe "TaskSportsFeedWeb.MatchLiveTest with mocks" do
    setup :verify_on_exit!

    test "mounts the LiveView even when the file is not found", %{conn: conn} do
      TaskSportsFeed.MockUtilsAPI
      |> expect(:load_match_ids, 2, fn _ -> {:error, :enoent} end)

      Application.put_env(:task_sports_feed, :utils, TaskSportsFeed.MockUtilsAPI)

      {:ok, _view, html} = live(conn, "/")
      assert html =~ "Live Match Status"

      Application.put_env(:task_sports_feed, :utils, TaskSportsFeed.UtilsAPI)
    end

    test "clicking the button on the page starts the match updates", %{
      conn: conn
    } do
      TaskSportsFeed.MockUtilsAPI
      |> expect(:load_match_ids, 2, fn _ -> {:ok, []} end)
      |> expect(:read_file, 1, fn _ -> {:error, :enoent} end)

      Application.put_env(:task_sports_feed, :utils, TaskSportsFeed.MockUtilsAPI)

      {:ok, view, _html} = live(conn, "/")

      assert view
             |> element("button#start_updates")
             |> then(fn elem ->
               :timer.sleep(50)
               elem
             end)
             |> render_click() =~
               "<button phx-click=\"start_updates\" type=\"button\" id=\"start_updates\" class=\"focus:outline-none text-white bg-green-700 hover:bg-green-800 focus:ring-4 focus:ring-green-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-green-600 dark:hover:bg-green-700 dark:focus:ring-green-800 \">\n  Start updates\n</button>"

      match_ids = [
        23_498_773,
        23_498_857,
        23_499_115,
        23_499_158,
        23_499_324,
        23_499_384,
        23_499_526,
        23_499_588,
        23_499_706,
        23_499_720
      ]

      refute Enum.any?(match_ids, fn match_id ->
               {:via, Registry, {TaskSportsFeed.MatchRegistry, match_id}}
               |> GenServer.whereis()
               |> is_pid()
             end)

      Application.put_env(:task_sports_feed, :utils, TaskSportsFeed.UtilsAPI)
    end
  end
end
