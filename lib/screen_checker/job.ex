defmodule ScreenChecker.Job do
  @moduledoc """
  GenServer that loads a list of screens into state on init and regularly logs their statuses to splunk
  """

  require Logger

  use GenServer

  @screens_env_var "SCREEN_CHECKER_SCREENS"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  ###

  @impl true
  def init(:ok) do
    Logger.info("Started ScreenChecker.Job")
    schedule_refresh(self())

    screens =
      @screens_env_var
      |> System.get_env()
      |> parse_screens()

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

    _ = log_screens(screens)

    {:noreply, screens}
  end

  defp schedule_refresh(pid) do
    Process.send_after(pid, :refresh, ScreenChecker.Time.next_minute_ms())
    :ok
  end

  defp log_screens(screens) do
    Logger.info("Logging status")

    _ =
      screens
      |> Task.async_stream(&log_status/1, ordered: false, timeout: 20_000)
      |> Stream.run()

    nil
  end

  defp log_status({ip, name}) do
    status = ScreenChecker.Fetch.fetch_status(ip)

    _ = ScreenChecker.Logger.log_screen_status(ip, name, status)
  end

  defp parse_screens(nil) do
    Logger.warn("#{@screens_env_var} environment variable is not defined")
    []
  end

  defp parse_screens(screens_json) do
    # JSON string of the form `[[ip, name], ...]` expected
    case Jason.decode(screens_json) do
      {:ok, screens} ->
        Enum.map(screens, &List.to_tuple/1)

      {:error, _} ->
        Logger.warn(
          "Failed to parse screen IPs/names from #{@screens_env_var} environment variable"
        )

        []
    end
  end
end
