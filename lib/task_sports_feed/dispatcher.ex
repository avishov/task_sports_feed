defmodule TaskSportsFeed.Dispatcher do
  alias TaskSportsFeed.Utils
  require Logger

  @moduledoc """
    Module responsible for processing the list of
    updates read from the file and starting GenServers
    for each match if it's not already started.
  """

  @doc """
    Processes the list of updates read from the file
    and starts GenServers for each match if it's not
    already started. If the GS exists, it adds the
    update to a FIFO queue in a corresponding GS.

  Returns tuple `{:ok, map()}` with a map, where
  the keys are match_ids and the value is 'true'
  if the GS was started for this match_id.
  Returns tuple `{:error, "File couldn't be read, {error}"}`
  when an error is returned when reading the file.
  """

  def dispatch_ordered(file \\ "priv/updates.json") do
    case Utils.read_file(file) do
      {:ok, decoded_json} ->
        Enum.reduce(decoded_json, %{}, fn update, started ->
          match_id = update["match_id"]

          unless Map.has_key?(started, match_id) do
            TaskSportsFeed.MatchWorker.start_link(match_id)
          end

          TaskSportsFeed.MatchWorker.enqueue_update(match_id, update)
          Map.put(started, match_id, true)
        end)
        |> then(&{:ok, &1})

      error ->
        Logger.error("Error when reading file: #{inspect(error)}")
        {:error, "File couldn't be read, #{inspect(error)}"}
    end
  end

  def calc_final(file \\ "priv/updates.json") do
    Utils.read_file!(file)
    |> Enum.reduce(%{}, fn update, statuses ->
      match_id = update["match_id"]

      if update["crash"], do: statuses, else: Map.put(statuses, match_id, update["status"])
    end)
  end
end
