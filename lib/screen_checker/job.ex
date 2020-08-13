defmodule ScreenChecker.Job do
  @moduledoc """
  Stateless GenServer that regularly checks screen statuses and logs results to splunk
  """

  require Logger

  use GenServer

  @solari_screens [
    {"172.19.43.25", "Ashmont"},
    {"172.19.36.25", "Central"},
    {"172.19.117.20", "Nubian Platform A"},
    {"172.19.117.21", "Nubian Platform C"},
    {"172.19.87.25", "Forest Hills Lobby"},
    {"172.19.87.26", "Forest Hills Upper Busway"},
    {"172.19.35.25", "Harvard"},
    {"172.19.76.25", "Haymarket"},
    {"172.19.10.25", "Maverick"},
    {"172.19.82.25", "Ruggles"},
    {"172.19.73.25", "Sullivan"},
    {"172.19.18.25", "Wonderland"}
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

    _ = Enum.each(@solari_screens, &log_status/1)

    {:noreply, state}
  end

  defp schedule_refresh(pid) do
    Process.send_after(pid, :refresh, next_minute_ms())
    :ok
  end

  defp log_status({ip, name}) do
    status = ScreenChecker.Fetch.fetch_status(ip)

    _ = ScreenChecker.Logger.log_screen_status(ip, name, status)
  end

  # milliseconds to wait until the start of the next minute
  defp next_minute_ms do
    now = DateTime.utc_now()
    {microsecond, _} = now.microsecond
    current_ms = now.second * 1000 + div(microsecond, 1000)
    60 * 1000 - current_ms
  end
end
