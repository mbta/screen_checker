defmodule ScreenChecker.GdsData.FetchTest do
  use ExUnit.Case

  alias ScreenChecker.GdsData.Fetch
  import SweetXml

  setup_all do
    %{gds_xml: File.read!(Path.join([File.cwd!(), "test", "sample_data", "gds_device_status.xml"]))}
  end

  describe "get_inner_xml_from_string_tag/1" do
    test "produces the same result as `xpath(\"//string/text()\")`", %{gds_xml: xml} do
      expected = xpath(xml, ~x"//string/text()") |> to_string()
      actual = Fetch.get_inner_xml_from_string_tag(xml)

      assert actual == expected
    end
  end
end
