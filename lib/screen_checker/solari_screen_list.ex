defmodule ScreenChecker.SolariScreenList do
  @moduledoc """
  Functions to fetch and parse the Solari screen list config from an env var containing a JSON string.

  Screen list is expected to be an array of objects of the form:
  ```ts
  {"ip": string, "name": string, "protocol"?: "http" | "https" | "https_insecure"}
  ```

  `protocol` defaults to `"http"` if not set.
  """

  require Logger

  @solari_screen_list_env_var "SOLARI_SCREEN_LIST"

  def fetch do
    case System.get_env(@solari_screen_list_env_var) do
      nil ->
        Logger.warn("#{@solari_screen_list_env_var} environment variable is not defined")
        []

      screens_json ->
        screens_json
        |> Jason.decode()
        |> parse_screens()
    end
  end

  defp parse_screens({:ok, screens}) do
    Enum.map(screens, &parse_screen/1)
  end

  defp parse_screens({:error, _}) do
    Logger.warn(
      "Failed to parse screen IPs/names from #{@solari_screen_list_env_var} environment variable"
    )

    []
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
