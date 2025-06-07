defmodule TaskSportsFeed.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TaskSportsFeedWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:task_sports_feed, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TaskSportsFeed.PubSub},
      {Registry, keys: :unique, name: TaskSportsFeed.MatchRegistry},
      TaskSportsFeedWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: TaskSportsFeed.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    TaskSportsFeedWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
