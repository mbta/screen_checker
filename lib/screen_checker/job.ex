defmodule ScreenChecker.Job do
  @moduledoc """
  GenServer that regularly checks screen statuses and logs results to splunk and a local log file
  """

  require Logger
  alias ScreenChecker.Screen

  use GenServer

  @refresh_ms 60 * 1000

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

  @solari_ips Enum.map(@solari_screens, fn {ip, _} -> ip end)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  ###

  @impl true
  def init(:ok) do
    init_state = Enum.into(@solari_screens, %{}, &init_screen_status/1)

    schedule_refresh(self())
    {:ok, init_state}
  end

  @impl true
  # Handle leaked :ssl_closed messages from Hackney.
  # Workaround for this issue: https://github.com/benoitc/hackney/issues/464
  def handle_info({:ssl_closed, _}, state) do
    {:noreply, state}
  end

  def handle_info(:refresh, state) do
    schedule_refresh(self())

    statuses = Enum.map(@solari_ips, fn ip -> {ip, ScreenChecker.Fetch.fetch_status(ip)} end)

    {:noreply, state, {:continue, statuses}}
  end

  @impl true
  def handle_continue([], state) do
    {:noreply, state}
  end

  def handle_continue([{ip, status} | rest], state) do
    {:noreply, put_status(state, ip, status), {:continue, rest}}
  end

  defp schedule_refresh(pid) do
    Process.send_after(pid, :refresh, @refresh_ms)
    :ok
  end

  defp init_screen_status({ip, name}) do
    {ip, %Screen{ip: ip, name: name}}
  end

  defp put_status(state, ip, status) do
    current_screen = state[ip]

    {result, screen} = Screen.set_status(current_screen, status)

    _ = if result == :updated, do: ScreenChecker.Logger.log_screen_status(screen)

    %{state | ip => screen}
  end
end
