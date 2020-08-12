defmodule ScreenChecker.Fetch do
  @headers []
  @opts [timeout: 2000, recv_timeout: 2000]

  def fetch_status(ip) do
    case fetch(ip) do
      {:ok, %{"Temperature" => -1}} -> :asleep
      {:ok, %{"Temperature" => _}} -> :up
      other -> other
    end
  end

  defp fetch(ip) do
    url = "http://#{ip}/cgi-bin/getstatus.cgi"

    with {:request, {:ok, response}} <- {:request, HTTPoison.get(url, @headers, @opts)},
         %{status_code: 200, body: body} <- response,
         {:parse, {:ok, %{"Temperature" => _} = parsed}} <- {:parse, Jason.decode(body)} do
      {:ok, parsed}
    else
      {:request, {:error, _}} -> :connection_error
      %{status_code: status_code} -> {:bad_status, status_code}
      {:parse, _} -> :invalid_response
      _ -> :error
    end
  end
end
