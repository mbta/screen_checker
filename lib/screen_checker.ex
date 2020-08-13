defmodule ScreenChecker do
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    Logger.info("Starting up ScreenChecker")

    children = [ScreenChecker.Job]

    opts = [strategy: :one_for_one, name: ScreenChecker.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
