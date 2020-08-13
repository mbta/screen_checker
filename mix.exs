defmodule ScreenChecker.MixProject do
  use Mix.Project

  def project do
    [
      app: :screen_checker,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        screen_checker: [
          # include_executables_for: [:windows],
          applications: [runtime_tools: :permanent]
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ScreenChecker, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.7"},
      {:logger_splunk_backend, git: "git@github.com:mbta/logger_splunk_backend.git"},
      {:timex, "~> 3.6"}
    ]
  end
end
