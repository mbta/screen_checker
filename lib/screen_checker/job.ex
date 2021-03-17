defmodule ScreenChecker.Job do
  @moduledoc """
  GenServer that loads a list of screens into state on init and regularly logs their statuses to splunk
  """

  require Logger

  use GenServer

  @screen_list_module Application.compile_env!(:screen_checker, :screen_list_module)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  ###

  @impl true
  def init(:ok) do
    Logger.info("Started ScreenChecker.Job")
    schedule_refresh(self())

    screens = @screen_list_module.fetch()

    {:ok, screens}
  end

  @impl true
  # Handle leaked :ssl_closed messages from Hackney.
  # Workaround for this issue: https://github.com/benoitc/hackney/issues/464
  def handle_info({:ssl_closed, _}, state) do
    {:noreply, state}
  end

  def handle_info(:refresh, screens) do
    schedule_refresh(self())

    Logger.info("Logging status")

    _ =
      screens
      |> Task.async_stream(&log_status/1, ordered: false, timeout: 20_000)
      |> Stream.run()

    {:noreply, screens}
  end

  defp schedule_refresh(pid) do
    Process.send_after(pid, :refresh, ScreenChecker.Time.next_minute_ms())
    :ok
  end

  defp log_status({protocol, ip, name}) do
    status = ScreenChecker.Fetch.fetch_status(ip, protocol)

    _ = ScreenChecker.Logger.log_screen_status(ip, name, status)
  end
end
