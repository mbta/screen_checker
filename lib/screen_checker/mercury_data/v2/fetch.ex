defmodule ScreenChecker.MercuryData.V2.Fetch do
  @moduledoc false

  import ScreenChecker.VendorData.Fetch, only: [make_and_parse_request: 5]

  @api_url_base "https://api.nexus.mercuryinnovation.com.au/API/mbta"
  @vendor_request_opts [hackney: [pool: :mercury_v2_api_pool]]

  def fetch_data(since) do
    headers = [{"apiKey", get_api_key()}]

    case make_and_parse_request(
           @api_url_base <> "/devices",
           headers,
           &Jason.decode/1,
           :mercury_v2,
           @vendor_request_opts
         ) do
      {:ok, parsed} ->
        prod_screens =
          Enum.filter(parsed, &match?(%{"stop" => %{"agency_id" => "mbta_prod"}}, &1))

        button_press_event_counts = fetch_button_press_events(prod_screens, since)

        {:ok,
         Enum.map(
           prod_screens,
           &fetch_device_info(&1, Map.get(button_press_event_counts, &1["device_id"], 0))
         )}

      :error ->
        :error
    end
  end

  defp get_api_key, do: System.get_env("MERCURY_V2_API_KEY")

  defp fetch_device_info(device, num_button_presses) do
    device_id = device["device_id"]
    headers = [{"apiKey", get_api_key()}]

    info =
      case make_and_parse_request(
             @api_url_base <> "/devices/#{device_id}",
             headers,
             &Jason.decode/1,
             :mercury_v2,
             @vendor_request_opts
           ) do
        {:ok, parsed} -> fetch_relevant_fields(parsed)
        :error -> %{device_id: device_id, state: :error}
      end

    Map.put(info, :button_presses, num_button_presses)
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

  defp fetch_button_press_events(devices, since) do
    since = DateTime.to_unix(since)
    now = DateTime.utc_now() |> DateTime.to_unix()
    device_ids = Enum.map_join(devices, "-", & &1["device_id"])

    case make_and_parse_request(
           @api_url_base <> "/allEvents/#{device_ids}/#{since}/#{now}",
           [{"apiKey", get_api_key()}],
           &Jason.decode/1,
           :mercury_v2,
           @vendor_request_opts
         ) do
      {:ok, parsed} ->
        for {device_id, events_map} <- parsed, into: %{} do
          num_button_presses =
            events_map
            |> Map.values()
            |> Enum.map(&Map.get(&1, "BUTTON_PRESS", []))
            |> Enum.concat()
            |> Enum.count()

          {device_id, num_button_presses}
        end

      _ ->
        %{}
    end
  end
end
