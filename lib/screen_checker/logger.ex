defmodule ScreenChecker.Logger do
  alias ScreenChecker.Screen

  require Logger

  @local_log_path Path.join(File.cwd!(), "screen_checker.txt")

  def log_screen_status(%Screen{name: name, ip: ip, status: status} = screen) do
    message = "#{status_to_message(status)} name=#{name} ip=#{ip}"

    _ =
      case status do
        :up -> Logger.info(message)
        _ -> Logger.error(message)
      end

    _ = write_local_log(screen)

    :ok
  end

  defp write_local_log(%Screen{name: name, ip: ip, status: status}) do
    timestamp =
      Timex.now("America/New_York")
      |> Timex.format!("{YYYY}-{0M}-{0D} {0h24}:{0m}:{0s}")

    status_string =
      case status do
        {:bad_status, status_code} -> "bad_http_status_#{status_code}"
        atom -> Atom.to_string(atom)
      end

    line = "#{timestamp} #{name} #{ip} #{status_string}\n"

    File.write!(@local_log_path, line, [:append, :utf8])
  end

  defp status_to_message(:asleep), do: "solari_screen_asleep"
  defp status_to_message(:connection_error), do: "solari_screen_connection_error"

  defp status_to_message({:bad_status, status_code}) do
    "solari_screen_bad_http_status status_code=#{status_code}"
  end

  defp status_to_message(:invalid_response), do: "solari_screen_invalid_response"
  defp status_to_message(:error), do: "solari_screen_unknown_error"
  defp status_to_message(:up), do: "solari_screen_recovered"
end
