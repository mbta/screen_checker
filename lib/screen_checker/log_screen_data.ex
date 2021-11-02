defmodule ScreenChecker.LogScreenData do
  @moduledoc false
  require Logger

  def log_message(message, data) do
    data_str =
      data
      |> Enum.map(&format_log_value/1)
      |> Enum.join(" ")

    Logger.info("#{message} #{data_str}")
  end

  defp format_log_value({key, value}) do
    value_str =
      case value do
        nil -> "null"
        _ -> "#{value}"
      end

    if String.contains?(value_str, " ") do
      "#{key}=\"#{value_str}\""
    else
      "#{key}=#{value_str}"
    end
  end
end
