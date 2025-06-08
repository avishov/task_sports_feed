defmodule TaskSportsFeed.DispatcherTest do
  use ExUnit.Case

  alias TaskSportsFeed.Dispatcher

  describe "TaskSportsFeed.Dispatcher.dispatch_ordered/1" do
    test "reads default file when no path is passed" do
      assert {:ok, content} = Dispatcher.dispatch_ordered()

      assert content == %{
               23_498_773 => true,
               23_498_857 => true,
               23_499_115 => true,
               23_499_158 => true,
               23_499_324 => true,
               23_499_384 => true,
               23_499_526 => true,
               23_499_588 => true,
               23_499_706 => true,
               23_499_720 => true
             }
    end

    test "reads another file when path is passed" do
      assert {:ok, content} = Dispatcher.dispatch_ordered("priv/test_updates.json")

      assert content == %{
               23_498_773 => true,
               23_498_857 => true,
               23_499_115 => true,
               23_499_324 => true,
               23_499_384 => true,
               23_499_526 => true,
               23_499_588 => true,
               23_499_706 => true
             }
    end

    test "returns an error when file under passed path doesn't exist" do
      assert {:error, "File couldn't be read, {:error, :enoent}"} ==
               Dispatcher.dispatch_ordered("priv/non_existent_file.json")
    end

    test "returns an error when file under passed path contains invalid JSON" do
      assert {:error,
              "File couldn't be read, {:error, %Jason.DecodeError{position: 6, token: nil, data: \"[\\n  {\\n]\\n\"}}"} ==
               Dispatcher.dispatch_ordered("priv/invalid.json")
    end

    test "starts all GenServers correctly for all matches in the file" do
      assert {:ok, _content} = Dispatcher.dispatch_ordered()

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

      assert Enum.all?(match_ids, fn match_id ->
               assert {:via, Registry, {TaskSportsFeed.MatchRegistry, match_id}}
                      |> GenServer.whereis()
                      |> is_pid()
             end)
    end
  end
end
