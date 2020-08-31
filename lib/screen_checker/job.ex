defmodule ScreenChecker.Job do
  @moduledoc """
  Stateless GenServer that regularly checks screen statuses and logs results to splunk
  """

  require Logger

  use GenServer

  @solari_screens [
    {"172.19.43.25", "ashmont"},
    {"172.19.36.25", "central"},
    {"172.19.117.20", "nubian_platform_a"},
    {"172.19.117.21", "nubian_platform_c"},
    {"172.19.87.25", "forest_hills_lobby"},
    {"172.19.87.26", "forest_hills_upper_busway"},
    {"172.19.35.25", "harvard"},
    {"172.19.76.25", "haymarket"},
    {"172.19.10.25", "maverick"},
    {"172.19.82.25", "ruggles"},
    {"172.19.73.25", "sullivan_square"},
    {"172.19.18.25", "wonderland"}
  ]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  ###

  @impl true
  def init(:ok) do
    Logger.info("Started ScreenChecker.Job")
    schedule_refresh(self())
    {:ok, %{}}
  end

  @impl true
  # Handle leaked :ssl_closed messages from Hackney.
  # Workaround for this issue: https://github.com/benoitc/hackney/issues/464
  def handle_info({:ssl_closed, _}, state) do
    {:noreply, state}
  end

  def handle_info(:refresh, state) do
    schedule_refresh(self())

    Logger.info("Logging status")

    _ =
      @solari_screens
      |> Task.async_stream(&log_status/1, ordered: false, timeout: 20_000)
      |> Stream.run()

    {:noreply, state}
  end

  defp schedule_refresh(pid) do
    Process.send_after(pid, :refresh, ScreenChecker.Time.next_minute_ms())
    :ok
  end

  defp log_status({ip, name}) do
    status = ScreenChecker.Fetch.fetch_status(ip)

    _ = ScreenChecker.Logger.log_screen_status(ip, name, status)
  end
end
