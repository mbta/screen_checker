defmodule ScreenChecker.ScreenList do
  @moduledoc """
  Functions to fetch and parse the screen list config from an env var containing a JSON string.

  Screen list is expected to be an array of objects of the form:
  ```ts
  {"ip": string, "name": string, "protocol"?: "http" | "https" | "https_insecure"}
  ```

  `protocol` defaults to `"https"` if not set.
  """

  require Logger

  @screens_env_var "SCREEN_LIST"

  def fetch do
    @screens_env_var
    |> System.get_env()
    |> parse_screens()
  end

  defp parse_screens(nil) do
    Logger.warn("#{@screens_env_var} environment variable is not defined")
    []
  end

  defp parse_screens(screens_json) do
    case Jason.decode(screens_json) do
      {:ok, screens} ->
        Enum.map(screens, &parse_screen/1)

      {:error, _} ->
        Logger.warn(
          "Failed to parse screen IPs/names from #{@screens_env_var} environment variable"
        )

        []
    end
  end

  defp parse_screen(%{"ip" => ip, "name" => name} = screen) do
    {parse_protocol(screen), ip, name}
  end

  defp parse_protocol(screen) do
    screen
    |> Map.get("protocol", "http")
    |> case do
      "http" -> :http
      "https" -> :https
      "https_insecure" -> :https_insecure
    end
  end
end
