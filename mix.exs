defmodule ScreenChecker.MixProject do
  use Mix.Project

  def project do
    [
      app: :screen_checker,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      dialyzer: [
        plt_add_apps: [:mix, :hackney],
        plt_add_deps: true
      ],
      releases: [
        linux: [
          include_executables_for: [:unix],
          applications: [runtime_tools: :permanent]
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger] ++ if(Mix.env() == :prod, do: [:ehmon], else: []),
      mod: {ScreenChecker, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.4.0", only: [:dev, :test]},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev, :test], runtime: false},
      {:ehmon, github: "mbta/ehmon", only: :prod},
      {:excoveralls, "== 0.12.3", only: :test},
      {:httpoison, "~> 1.7"},
      {:jason, "~> 1.2"},
      {:logger_splunk_backend, "~> 2.0.0"},
      {:mock, "~> 0.3.5", only: :test},
      {:timex, "~> 3.7"},
      {:sweet_xml, "~> 0.7.0"}
    ]
  end
end
