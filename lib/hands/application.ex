defmodule Hands.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HandsWeb.Telemetry,
      Hands.Repo,
      {DNSCluster, query: Application.get_env(:hands, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Hands.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Hands.Finch},
      Hands.Browse.MatchmakerServer,
      Hands.Chat.RoomRegistry,
      Hands.Chat.RoomDynamicSupervisor,
      Hands.Chat.RoomKeeperServer,
      # Start a worker by calling: Hands.Worker.start_link(arg)
      # {Hands.Worker, arg},
      # Start to serve requests, typically the last entry
      HandsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Hands.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HandsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
