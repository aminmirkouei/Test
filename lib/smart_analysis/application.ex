defmodule SmartAnalysis.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SmartAnalysisWeb.Telemetry,
      SmartAnalysis.Repo,
      {DNSCluster, query: Application.get_env(:smart_analysis, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SmartAnalysis.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: SmartAnalysis.Finch},
      # Start a worker by calling: SmartAnalysis.Worker.start_link(arg)
      # {SmartAnalysis.Worker, arg},
      # Start to serve requests, typically the last entry
      SmartAnalysisWeb.Endpoint,

      TwMerge.Cache
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SmartAnalysis.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SmartAnalysisWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
