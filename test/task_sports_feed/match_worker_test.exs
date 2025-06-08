defmodule TaskSportsFeed.MatchWorkerTest do
  use ExUnit.Case, async: true

  alias TaskSportsFeed.MatchWorker

  setup do
    match_id = :test_match_
    {:ok, pid} = MatchWorker.start_link(match_id)
    %{match_id: match_id, pid: pid}
  end

  describe "start_link/1" do
    test "starts the GenServer and registers it via Registry", %{match_id: match_id} do
      assert {:via, Registry, {TaskSportsFeed.MatchRegistry, ^match_id}} =
               MatchWorker.via(match_id)

      [{pid, nil}] = Registry.lookup(TaskSportsFeed.MatchRegistry, match_id)
      assert is_pid(pid)
    end
  end

  describe "enqueue_update/2" do
    test "sends an update message to the GenServer", %{match_id: match_id} do
      assert :ok =
               MatchWorker.enqueue_update(match_id, %{
                 "name" => "Real Madrid vs Barcelona",
                 "status" => "paused",
                 "crash" => true,
                 "delay" => 9900
               })
    end
  end

  describe "internal state and ordering" do
    test "enqueues multiple updates in order", %{match_id: match_id} do
      MatchWorker.enqueue_update(match_id, %{
        "name" => "Juventus vs Napoli",
        "status" => "completed",
        "crash" => true,
        "delay" => 688
      })

      MatchWorker.enqueue_update(match_id, %{
        "name" => "Real Madrid vs Barcelona",
        "status" => "paused",
        "crash" => true,
        "delay" => 999
      })

      # allow casts to process
      :timer.sleep(50)
      state = MatchWorker.get_state(match_id)
      queue = state.queue
      # the queue contains ONE element, because
      # the other one is being currently processed
      assert :queue.len(queue) == 1

      assert :queue.member(
               %{
                 "name" => "Real Madrid vs Barcelona",
                 "status" => "paused",
                 "crash" => true,
                 "delay" => 999
               },
               queue
             )
    end
  end

  describe "fault tolerance" do
    test "handles unexpected messages gracefully", %{pid: pid} do
      send(pid, :unexpected)
      assert Process.alive?(pid)
    end

    test "handles :done_processing message when the queue is empty gracefully", %{
      pid: pid
    } do
      GenServer.cast(pid, :done_processing)
      assert Process.alive?(pid)
    end
  end

  describe "get_state/1" do
    test "returns the current GenServer state", %{match_id: match_id} do
      MatchWorker.enqueue_update(match_id, %{
        "name" => "Juventus vs Napoli",
        "status" => "completed",
        "crash" => true,
        "delay" => 688
      })

      # double insert because the first one will be processed immediately
      MatchWorker.enqueue_update(match_id, %{
        "name" => "Juventus vs Napoli",
        "status" => "completed",
        "crash" => true,
        "delay" => 688
      })

      :timer.sleep(20)
      state = MatchWorker.get_state(match_id)
      assert is_map(state)
      assert state.match_id == match_id

      assert :queue.member(
               %{
                 "name" => "Juventus vs Napoli",
                 "status" => "completed",
                 "crash" => true,
                 "delay" => 688
               },
               state.queue
             )
    end
  end
end
