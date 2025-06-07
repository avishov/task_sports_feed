defmodule TaskSportsFeed.MatchWorker do
  use GenServer
  require Logger

  @moduledoc """
    Module holding GenServer definition for
    workers storing the FIFO queue of match
    updates and processing said updates.
  """

  @doc """
    Starts a GenServer and registers it under the
    name that is `match_id` passed to this function.
  """
  def start_link(match_id) do
    GenServer.start_link(__MODULE__, match_id, name: via(match_id))
  end

  @doc """
    Translates passed match_id into a tuple allowing
    looking up a GS through it's name in the registry.

  Returns `{:via, Registry, {TaskSportsFeed.MatchRegistry, match_id}}`.
  """
  def via(match_id), do: {:via, Registry, {TaskSportsFeed.MatchRegistry, match_id}}

  @doc """
    Passes the parsed match update to it's
    corresponding GenServer identified via match_id.
  """
  def enqueue_update(match_id, update) do
    GenServer.cast(via(match_id), {:enqueue, update})
  end

  @doc """
    Sets the initial state of the GenServer.
    Each GS worker starts with the following values:
    - match_id: the same match_id that the GS is registered under,
    - queue: empty FIFO queue,
    - processing: flag signaling if the GS is currently processing something; set to false by default.

  Returns `{:ok, map()}`.
  """
  def init(match_id), do: {:ok, %{match_id: match_id, queue: :queue.new(), processing: false}}

  # Adds a parsed match update to the end of the FIFO queue
  # that's held in the state of the GS.
  # If GS is not busy, it tries to process the update immediately.
  #
  def handle_cast({:enqueue, update}, state) do
    state = %{state | queue: :queue.in(update, state.queue)}
    maybe_process(state)
  end

  # Handles the message from the GS that it's done
  # processing the current match update by possibly
  # sending a message to trigger starting to process the next one.

  def handle_cast(:done_processing, state), do: maybe_process(%{state | processing: false})

  # Handles the message from the GS that it should
  # process the next match update from the queue.
  # If there is an entry in the queue, retrieves it
  # and simulates the delay.
  # If the update simulates a crash, it returns an error
  # to the logs instead of pushing the update to the webUI.
  # If update is not a crash, sends it to webUI via sockets.

  def handle_info(:process_next, state) do
    case :queue.out(state.queue) do
      {{:value, update}, rest} ->
        # Delay inside GenServer to preserve order
        Process.sleep(trunc(update["delay"] / 100))

        if update["crash"] do
          Logger.error("Match #{update["match_id"]} crashed: Simulated crash")
        else
          Phoenix.PubSub.broadcast(
            TaskSportsFeed.PubSub,
            "match:#{update["match_id"]}",
            {:status_update,
             %{
               match_id: update["match_id"],
               name: update["name"],
               status: update["status"]
             }}
          )
        end

        # Continue to next item
        maybe_process(%{state | queue: rest, processing: false})

      {:empty, _} ->
        {:noreply, %{state | processing: false}}
    end
  end

  # Decides whether to process the update from
  # the queue or not by checking if it's empty.
  # If it's empty, GS simply continues being in a
  # standby state.
  # If the queue is not empty, it sends the GS a
  # message to process the next entry from the queue.

  defp maybe_process(%{processing: false, queue: queue} = state) do
    if :queue.is_empty(queue) do
      {:noreply, %{state | processing: false}}
    else
      send(self(), :process_next)
      {:noreply, %{state | processing: true}}
    end
  end

  defp maybe_process(state), do: {:noreply, state}
end
