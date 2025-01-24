defmodule ScreenChecker.GdsData.Fetch do
  @moduledoc false

  import SweetXml
  use Timex
  require Logger

  import ScreenChecker.VendorData.Fetch, only: [make_and_parse_request: 4]

  @gds_api_url "https://dmsmbta.gds.com/DMSService.asmx"
  @token_url_base "#{@gds_api_url}/GetToken"
  @device_list_url_base "#{@gds_api_url}/GetDevicesList"

  @vendor_name :gds
  @vendor_request_opts []

  def fetch_data_for_current_day do
    # GDS API Dates are in Central European time
    utc_time = DateTime.utc_now()
    {:ok, italy_time} = DateTime.shift_zone(utc_time, "Europe/Rome")
    italy_date = DateTime.to_date(italy_time)

    with {:get_token, {:ok, token}} <- {:get_token, get_token()},
         {:fetch_devices_data, {:ok, devices_data}} <-
           {:fetch_devices_data, fetch_devices_data(token, italy_date)} do
      sns = Map.keys(devices_data)
      {:ok, merge_device_and_sn_data(sns, devices_data)}
    else
      {step, :error} ->
        _ = Logger.info("gds_fetch_error #{step}")
        :error
    end
  end

  defp get_token(num_retries \\ 2) do
    case {do_get_token(), num_retries} do
      {:error, 0} -> :error
      {:error, _} -> get_token(num_retries - 1)
      {{:ok, token}, _} -> {:ok, token}
    end
  end

  defp do_get_token do
    params = %{
      "UserName" => System.get_env("GDS_DMS_USERNAME"),
      "Password" => System.get_env("GDS_DMS_PASSWORD"),
      "Company" => "M B T A",
      "AspxAutoDetectCookieSupport" => 1
    }

    @token_url_base
    |> build_url(params)
    |> make_and_parse_request(&parse_token/1, @vendor_name, @vendor_request_opts)
  end

  defp parse_token(xml) do
    token =
      xml
      # |> xpath(~x"//string/text()")
      # ^ Several orders of magnitude slower!
      |> get_inner_xml_from_string_tag()
      |> xpath(~x"//Token/text()"s)

    {:ok, token}
  end

  defp fetch_devices_data(token, date) do
    params = %{
      "Token" => token,
      "Year" => date.year,
      "Month" => date.month,
      "Day" => date.day,
      "AspxAutoDetectCookieSupport" => 1
    }

    @device_list_url_base
    |> build_url(params)
    |> make_and_parse_request(&parse_devices_data/1, @vendor_name, @vendor_request_opts)
  end

  defp parse_devices_data(xml) do
    %{logs: logs} =
      xml
      # |> xpath(~x"//string/text()")
      # ^ Several orders of magnitude slower!
      |> get_inner_xml_from_string_tag()
      |> xmap(
        logs: [
          ~x"//Devices/Device"l,
          name: ~x"./name/text()"s,
          battery: ~x"./battery/text()"s,
          temp: ~x"./temp_internal/text()"s,
          humidity: ~x"./humidity/text()"s,
          call: ~x"./LastCall/text()"s,
          sn: ~x"./sn/text()"s,
          ping_count: ~x"./Ping24/text()"s
        ]
      )

    devices_data =
      logs
      |> Enum.map(&parse_device_log/1)
      |> Enum.into(%{})

    {:ok, devices_data}
  end

  # Gets content of the <string> tag and does basic character unescaping on it to produce a new XML string.
  # (We don't need to handle any of the extra special escape formats like &#...; or CDATA. They aren't used for this data.)
  # (If they ever start being used, xpath functions will fail on the improperly-unescaped XML and we'll get alerted about missing logs.)
  def get_inner_xml_from_string_tag(xml) do
    ~r|<string xmlns="http://tempuri\.org/">(.*)</string>|
    |> Regex.run(xml, capture: :all_but_first)
    |> hd()
    |> String.replace(~w[&quot; &apos; &lt; &gt; &amp;], &unescape_special_char/1)
  end

  defp unescape_special_char("&quot;"), do: "\""
  defp unescape_special_char("&apos;"), do: "'"
  defp unescape_special_char("&lt;"), do: "<"
  defp unescape_special_char("&gt;"), do: ">"
  defp unescape_special_char("&amp;"), do: "&"

  defp parse_device_log(%{
         battery: battery_str,
         call: call_str,
         humidity: humidity_str,
         name: screen_name,
         sn: screen_sn,
         temp: temp_str,
         ping_count: ping_count
       }) do
    {screen_sn,
     %{
       battery: String.to_float(battery_str),
       humidity: String.to_float(humidity_str),
       temperature: String.to_float(temp_str),
       log_time: parse_datetime(call_str),
       screen_name: screen_name,
       time: DateTime.utc_now(),
       ping_count: ping_count
     }}
  end

  defp parse_datetime(s) do
    with {:ok, naive_datetime} <- Timex.parse(s, "%-m/%-d/%Y %-I:%M:%S %p", :strftime),
         {:ok, dt} <- DateTime.from_naive(naive_datetime, "Europe/Rome"),
         {:ok, utc_dt} <- DateTime.shift_zone(dt, "Etc/UTC") do
      utc_dt
    else
      _ -> nil
    end
  end

  defp merge_device_and_sn_data(screen_sns, devices_data) do
    Enum.map(screen_sns, fn sn ->
      devices_data
      |> Map.get(sn)
      |> Map.put(:screen_sn, sn)
    end)
  end

  defp build_url(base_url, params) when map_size(params) == 0 do
    base_url
  end

  defp build_url(base_url, params) do
    "#{base_url}?#{URI.encode_query(params)}"
  end
end
