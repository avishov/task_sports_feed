defmodule TaskSportsFeedWeb.MatchLive do
  use TaskSportsFeedWeb, :live_view
  require Logger

  @moduledoc """
    View for triggering the match data update
    and displaying the latest updates as they happen
    in real-time.
  """

  @doc """
  Retrieves all match_ids from the update file and
  subscribes to all of the PubSub sockets created for
  every match to receive updates for each one of them.
  When that is done, it mounts the view.

  Returns `{:ok, socket}`.
  """
  def mount(_params, _session, socket) do
    case TaskSportsFeed.Utils.load_match_ids() do
      {:ok, match_ids} ->
        if connected?(socket) do
          Enum.each(match_ids, fn id ->
            Phoenix.PubSub.subscribe(TaskSportsFeed.PubSub, "match:#{id}")
          end)
        end

        {:ok, assign(socket, matches: %{}, update_started: false)}

      error ->
        Logger.error("Error while loading match_ids: #{inspect(error)}")
        {:ok, assign(socket, matches: %{}, update_started: false)}
    end
  end

  @doc """
  When a :status_update is received from any of the
  sockets the view is subscribed to, update the map
  of matches in memory to contain the freshly
  received data.

  Returns `{:noreply, socket}`.
  """
  def handle_info({:status_update, %{match_id: id} = match}, socket) do
    {:noreply, assign(socket, matches: Map.put(socket.assigns.matches, id, match))}
  end

  @doc """
  When a "start_updates" event is received from the
  button visible in the view, this function triggers
  the update of match data from a 'priv/updates.json' file.

  Returns `{:noreply, socket}`.
  """
  def handle_event("start_updates", _value, socket) do
    case TaskSportsFeed.Dispatcher.dispatch_ordered() do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:update_started, true)
         |> put_flash(:info, "Update triggered successfully")}

      {:error, error} ->
        {:noreply,
         socket
         |> put_flash(:error, error)}
    end
  end
end
