defmodule ScreenChecker.Fetch do
  @moduledoc false

  @headers []
  @opts [timeout: 2_000, recv_timeout: 15_000]

  def fetch_status(ip) do
    case fetch(ip) do
      {:ok, %{"Temperature" => -1}} -> :asleep
      {:ok, %{"Temperature" => _}} -> :up
      other -> other
    end
  end

  defp fetch(ip) do
    with {:request, {:ok, response}} <- {:request, request(ip)},
         %{status_code: 200, body: body} <- response,
         {:parse, {:ok, %{"Temperature" => _} = parsed}} <- {:parse, Jason.decode(body)} do
      {:ok, parsed}
    else
      {:request, {:error, _}} -> {:connection_error, switch_pingable?(ip)}
      %{status_code: status_code} -> {:bad_status, status_code}
      {:parse, _} -> :invalid_response
      _ -> :error
    end
  end

  defp request(ip) do
    HTTPoison.get("http://#{ip}/cgi-bin/getstatus.cgi", @headers, @opts)
  end

  defp switch_pingable?(screen_ip) do
    screen_ip
    |> screen_ip_to_switch_ip()
    |> ping_once()
    |> case do
      {_, 0} -> true
      _ -> false
    end
  end

  defp screen_ip_to_switch_ip(ip) do
    String.replace(ip, ~r|\.\d+$|, ".1")
  end

  defp ping_once(ip) do
    cmd_args =
      case :os.type() do
        {:win32, _} -> ~w[-n 1 #{ip}]
        {:unix, _} -> ~w[-c 1 #{ip}]
      end

    System.cmd("ping", cmd_args, stderr_to_stdout: true)
  end
end
