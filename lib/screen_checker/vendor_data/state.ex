defmodule ScreenChecker.VendorData.State do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      use GenServer
      require Logger

      def start_link(opts \\ []) do
        GenServer.start_link(__MODULE__, :ok, opts)
      end

      def schedule_refresh(pid, ms) do
        Process.send_after(pid, :refresh, ms)
        :ok
      end

      ###
      @impl true
      def init(:ok) do
        Logger.info("Started #{__MODULE__}")
        state = DateTime.utc_now()
        schedule_refresh(self(), ScreenChecker.Time.next_minute_ms())
        {:ok, state}
      end

      @impl true
      def handle_info(:refresh, old_state) do
        Logger.info("#{__MODULE__}: Logging status")
        new_state = DateTime.utc_now()

        _ = Task.start(fn -> do_log(old_state) end)

        schedule_refresh(self(), ScreenChecker.Time.next_minute_ms())
        {:noreply, new_state}
      end

      # Handle leaked :ssl_closed messages from Hackney.
      # Workaround for this issue: https://github.com/benoitc/hackney/issues/464
      def handle_info({:ssl_closed, _}, state) do
        {:noreply, state}
      end
    end
  end
end
