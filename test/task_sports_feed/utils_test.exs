defmodule TaskSportsFeed.UtilsTest do
  use ExUnit.Case, async: true

  alias TaskSportsFeed.UtilsAPI, as: Utils

  setup do
    Application.get_env(:task_sports_feed, :utils, TaskSportsFeed.Utils)
    :ok
  end

  describe "TaskSportsFeed.Utils.read_file/1" do
    test "reads default file when no path is passed" do
      assert {:ok, content} = Utils.read_file()

      assert hd(content) == %{
               "crash" => false,
               "delay" => 551,
               "match_id" => 23_499_115,
               "name" => "Real Madrid vs Barcelona",
               "status" => "active"
             }
    end

    test "reads another file when path is passed" do
      assert {:ok, content} = Utils.read_file("priv/test_updates.json")

      assert hd(content) == %{
               "crash" => false,
               "delay" => 624,
               "match_id" => 23_499_384,
               "name" => "Atletico Madrid vs Sevilla",
               "status" => "completed"
             }
    end

    test "returns an error when file under passed path doesn't exist" do
      assert {:error, :enoent} = Utils.read_file("priv/non_existent_file.json")
    end

    test "returns an error when file under passed path contains invalid JSON" do
      assert {:error, %Jason.DecodeError{}} = Utils.read_file("priv/invalid.json")
    end
  end

  describe "TaskSportsFeed.Utils.read_file!/1" do
    test "reads default file when no path is passed" do
      assert content = Utils.read_file!()

      assert hd(content) == %{
               "crash" => false,
               "delay" => 551,
               "match_id" => 23_499_115,
               "name" => "Real Madrid vs Barcelona",
               "status" => "active"
             }
    end

    test "reads another file when path is passed" do
      assert content = Utils.read_file!("priv/test_updates.json")

      assert hd(content) == %{
               "crash" => false,
               "delay" => 624,
               "match_id" => 23_499_384,
               "name" => "Atletico Madrid vs Sevilla",
               "status" => "completed"
             }
    end

    test "returns an error when file under passed path doesn't exist" do
      assert_raise File.Error, fn ->
        Utils.read_file!("priv/non_existent_file.json")
      end
    end

    test "returns an error when file under passed path contains invalid JSON" do
      assert_raise Jason.DecodeError, fn ->
        Utils.read_file!("priv/invalid.json")
      end
    end
  end

  # the following function reuses the above functions
  # so there is no need to test each path again

  describe "TaskSportsFeed.Utils.load_match_ids/1" do
    test "reads default file when no path is passed" do
      assert {:ok, content} = Utils.load_match_ids()

      assert content == [
               23_499_115,
               23_498_773,
               23_499_706,
               23_499_384,
               23_499_526,
               23_499_588,
               23_498_857,
               23_499_324,
               23_499_158,
               23_499_720
             ]
    end

    test "reads another file when path is passed" do
      assert {:ok, content} = Utils.load_match_ids("priv/test_updates.json")

      assert content == [
               23_499_384,
               23_499_324,
               23_499_115,
               23_498_773,
               23_499_706,
               23_499_526,
               23_499_588,
               23_498_857
             ]
    end

    test "returns an error when file under passed path contains invalid JSON" do
      assert {:error, %Jason.DecodeError{}} = Utils.load_match_ids("priv/invalid.json")
    end
  end
end
