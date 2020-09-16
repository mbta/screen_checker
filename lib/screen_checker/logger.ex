defmodule ScreenChecker.Logger do
  @moduledoc false

  require Logger

  def log_screen_status(ip, name, status) do
    message = "#{status_to_message(status)} name=#{name} ip=#{ip}"

    _ = Logger.info(message)

    :ok
  end

  defp status_to_message(:asleep), do: "solari_screen_asleep"

  defp status_to_message({:connection_error, switch_ping_succeeded?}) do
    "solari_screen_connection_error switch_ping_succeeded=#{switch_ping_succeeded?}"
  end

  defp status_to_message({:bad_status, status_code}) do
    "solari_screen_bad_http_status status_code=#{status_code}"
  end

  defp status_to_message(:invalid_response), do: "solari_screen_invalid_response"
  defp status_to_message(:error), do: "solari_screen_unknown_error"
  defp status_to_message(:up), do: "solari_screen_up"
end
