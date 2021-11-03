defmodule ScreenChecker.VendorData.Logger do
  @moduledoc false

  require Logger

  @spec log_data((() -> [map()]), atom(), String.t()) :: :ok
  def log_data(fetch_fn, vendor_name, application_key) do
    if not is_nil(System.get_env(application_key)) do
      case fetch_fn.() do
        {:ok, data} -> Enum.each(data, &log_screen_entry(&1, vendor_name))
        :error -> nil
      end
    end

    :ok
  end

  defp log_screen_entry(screen_data, vendor_name) do
    ScreenChecker.LogScreenData.log_message("#{vendor_name}_data_report", screen_data)
  end
end
