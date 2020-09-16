defmodule ScreenChecker.FetchTest do
  use ExUnit.Case
  import Mock
  alias ScreenChecker.{Fetch, Ping}

  describe "fetch_status/1" do
    test "sends request to the correct url" do
      with_mock HTTPoison, get: fn _url, _headers, _opts -> :anything end do
        _ = Fetch.fetch_status("1.2.3.4")
        assert_called(HTTPoison.get("http://1.2.3.4/cgi-bin/getstatus.cgi", :_, :_))
      end
    end

    test "returns :asleep when response body has `\"Temperature\": -1`" do
      with_mock HTTPoison,
        get: fn _url, _headers, _opts -> httpoison_ok(~s[{"Temperature":-1}]) end do
        assert :asleep == Fetch.fetch_status("")
      end
    end

    test "returns :up when response body has `\"Temperature\": <anything but -1>`" do
      with_mock HTTPoison, get: fn _, _, _ -> httpoison_ok(~s[{"Temperature":0}]) end do
        assert :up == Fetch.fetch_status("")
      end
    end

    test "returns {:connection_error, <switch ping result>} when request failed" do
      with_mocks [
        {HTTPoison, [], get: fn _, _, _ -> {:error, :reason} end},
        {Ping, [], switch_pingable?: fn _ -> true end}
      ] do
        assert {:connection_error, true} == Fetch.fetch_status("")
      end
    end

    test "returns {:bad_status, <status>} when a non-200 response was received" do
      with_mock HTTPoison, get: fn _, _, _ -> httpoison_ok("", 404) end do
        assert {:bad_status, 404} == Fetch.fetch_status("")
      end
    end

    test "returns :invalid_response when an unexpected response body was received" do
      with_mock HTTPoison, get: fn _, _, _ -> httpoison_ok(~s[{"SomethingElse":true}]) end do
        assert :invalid_response == Fetch.fetch_status("")
      end
    end

    test "returns :error in all other cases" do
      with_mock HTTPoison, get: fn _, _, _ -> :something_else end do
        assert :error == Fetch.fetch_status("")
      end
    end
  end

  defp httpoison_ok(body, status_code \\ 200) do
    {:ok, %{status_code: status_code, body: body}}
  end
end
