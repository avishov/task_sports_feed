defmodule TaskSportsFeed.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TaskSportsFeedWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:task_sports_feed, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TaskSportsFeed.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: TaskSportsFeed.Finch},
      # Start a worker by calling: TaskSportsFeed.Worker.start_link(arg)
      # {TaskSportsFeed.Worker, arg},
      # Start to serve requests, typically the last entry
      TaskSportsFeedWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TaskSportsFeed.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TaskSportsFeedWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
