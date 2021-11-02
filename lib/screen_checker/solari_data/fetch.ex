defmodule ScreenChecker.SolariData.Fetch do
  @moduledoc false
  alias ScreenChecker.SolariData.Ping

  @headers []
  @opts [timeout: 2_000, recv_timeout: 15_000]

  def fetch_status(ip, protocol) do
    case fetch(ip, protocol) do
      {:ok, %{"Temperature" => -1, "Environment Light" => -1}} -> :asleep
      {:ok, %{"Temperature" => t}} -> {:up, t}
      other -> other
    end
  end

  defp fetch(ip, protocol) do
    with {:request, {:ok, response}} <- {:request, request(ip, protocol)},
         %{status_code: 200, body: body} <- response,
         {:parse, {:ok, %{"Temperature" => _} = parsed}} <- {:parse, Jason.decode(body)} do
      {:ok, parsed}
    else
      {:request, {:error, _}} -> {:connection_error, Ping.switch_pingable?(ip)}
      %{status_code: status_code} -> {:bad_status, status_code}
      {:parse, _} -> :invalid_response
      _ -> :error
    end
  end

  defp request(ip, :http) do
    HTTPoison.get("http://#{ip}/cgi-bin/getstatus.cgi", @headers, @opts)
  end

  defp request(ip, :https) do
    HTTPoison.get("https://#{ip}/cgi-bin/getstatus.cgi", @headers, @opts)
  end

  defp request(ip, :https_insecure) do
    opts = Keyword.put(@opts, :hackney, [:insecure])

    HTTPoison.get("https://#{ip}/cgi-bin/getstatus.cgi", @headers, opts)
  end
end
