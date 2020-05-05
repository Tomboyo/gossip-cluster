defmodule GossipCluster.MixProject do
  use Mix.Project

  def project do
    [
      app: :gossip_cluster,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        gossip_cluster: [
          cookie: "gossip-cluster-cookie"
        ]
      ]
    ]
  end

  def application do
    [
      mod: {GossipCluster.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end
end
