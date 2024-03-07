defmodule ScreenChecker.MercuryData.V2.Fetch do
  @moduledoc false

  import ScreenChecker.VendorData.Fetch, only: [make_and_parse_request: 5]

  @api_url_base "https://api.nexus.mercuryinnovation.com.au/API/mbta/devices"
  @vendor_request_opts [hackney: [pool: :mercury_v2_api_pool]]

  def fetch_data do
    headers = [{"apiKey", get_api_key()}]

    case make_and_parse_request(
           @api_url_base,
           headers,
           &Jason.decode/1,
           :mercury_v2,
           @vendor_request_opts
         ) do
      {:ok, parsed} -> {:ok, Enum.map(parsed, &fetch_device_info/1)}
      :error -> :error
    end
  end

  defp get_api_key, do: System.get_env("MERCURY_V2_API_KEY")

  defp fetch_device_info(device) do
    device_id = device["device_id"]
    headers = [{"apiKey", get_api_key()}]

    case make_and_parse_request(
           @api_url_base <> "/#{device_id}",
           headers,
           &Jason.decode/1,
           :mercury_v2,
           @vendor_request_opts
         ) do
      {:ok, parsed} -> fetch_relevant_fields(parsed)
      :error -> %{device_id: device_id, state: :error}
    end
  end

  defp fetch_relevant_fields(device) do
    %{
      "device_id" => device_id,
      "screens" => [screen],
      "battery_level" => battery,
      "stop" => %{"stop_id" => stop_id}
    } = device

    screen_fields = fetch_relevant_screen_fields(screen)

    Map.merge(screen_fields, %{device_id: device_id, stop_id: stop_id, battery: battery})
  end

  defp fetch_relevant_screen_fields(status) do
    %{
      "latest_logs" => %{
        "GSMStatus" => %{"rssi" => signal_strength},
        "status" => %{"internal_temp" => temperature, "battery_reading" => battery_voltage},
        "GSMBoot" => %{"serial" => connectivity_used},
        "boot" => %{"reset_cause" => connect_reason}
      },
      "State" => state,
      "Options" => %{"Name" => name},
      "last_heartbeat" => last_heartbeat
    } = status

    %{
      state: state,
      name: name,
      battery_voltage: battery_voltage,
      connect_reason: connect_reason,
      connectivity_used: connectivity_used,
      last_heartbeat: last_heartbeat,
      signal_strength: signal_strength,
      temperature: temperature
    }
  end
end
