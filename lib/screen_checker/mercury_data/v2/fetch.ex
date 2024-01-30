defmodule ScreenChecker.MercuryData.V2.Fetch do
  @moduledoc false

  import ScreenChecker.VendorData.Fetch, only: [make_and_parse_request: 5]

  @api_url_base "https://api.nexus.mercuryinnovation.com.au/API/mbta/devices"
  @vendor_request_opts [hackney: [pool: :mercury_v2_api_pool]]
  @headers [{"apiKey", System.get_env("MERCURY_V2_API_KEY")}]

  def fetch_data do
    case make_and_parse_request(
           @api_url_base,
           @headers,
           &Jason.decode/1,
           :mercury_v2,
           @vendor_request_opts
         ) do
      {:ok, parsed} -> Enum.map(parsed, &fetch_device_info/1)
      :error -> :error
    end
  end

  defp fetch_device_info(device) do
    case make_and_parse_request(
           @api_url_base <> "/#{device["device_id"]}",
           @headers,
           &Jason.decode/1,
           :mercury_v2,
           @vendor_request_opts
         ) do
      {:ok, parsed} -> {:ok, Enum.map(parsed, &fetch_relevant_fields/1)}
      :error -> :error
    end
  end

  defp fetch_relevant_fields(%{
         "State" => state,
         "screens" => [screen],
         "Options" => %{"Name" => name}
       }) do
    status_fields = fetch_relevant_status_fields(screen)

    Map.merge(status_fields, %{
      state: state,
      name: name
    })
  end

  defp fetch_relevant_status_fields(status) do
    # Need to figure out from Mercury where the other fields below are.
    # Could not find them in the response from the new endpoint.
    # https://mbta.slack.com/archives/C059FPCQBNG/p1706648508022929
    # %{"latest_logs" => %{"GSMStatus" => %{"rssi" => signal_strength}, "status" => %{"internal_temp" => temperature}}}
    %{
      battery: "Battery",
      battery_voltage: "BatteryVoltage",
      external_battery: "ExternalBattery",
      uptime: "Uptime",
      connect_reason: "ConnectReason",
      connectivity_used: "ConnectivityUsed",
      last_image_time: "last_image_time",
      last_data_time: "last_data_time"
    }
    |> Enum.map(fn {name, status_key} -> {name, Map.get(status, status_key)} end)
    |> Enum.into(%{})
  end
end
