defmodule ScreenChecker.SolariData.FetchTest do
  use ExUnit.Case

  import Mock
  alias ScreenChecker.SolariData.{Fetch, Ping}

  describe "fetch_status/1" do
    test "sends request to the correct url" do
      with_mock HTTPoison, get: fn _url, _headers, _opts -> :anything end do
        _ = Fetch.fetch_status("1.2.3.4", :http)
        assert_called(HTTPoison.get("http://1.2.3.4/cgi-bin/getstatus.cgi", :_, :_))
      end
    end

    test "uses an https request when passed :https" do
      with_mock HTTPoison, get: fn _, _, _ -> httpoison_ok(~s|{"Temperature":42}|) end do
        _ = Fetch.fetch_status("1.2.3.4", :https)

        assert_called(HTTPoison.get("https://1.2.3.4/cgi-bin/getstatus.cgi", :_, :_))
      end
    end

    test "uses an insecure https request when passed :https_insecure" do
      with_mock HTTPoison, get: fn _, _, _ -> httpoison_ok(~s|{"Temperature":42}|) end do
        _ = Fetch.fetch_status("1.2.3.4", :https_insecure)

        assert_called(
          HTTPoison.get("https://1.2.3.4/cgi-bin/getstatus.cgi", :_,
            hackney: [:insecure],
            timeout: 2_000,
            recv_timeout: 15_000
          )
        )
      end
    end

    test ~s|returns :asleep when response body has `"Temperature": -1`, "Environment Light": -1| do
      with_mock HTTPoison,
        get: fn _url, _headers, _opts ->
          httpoison_ok(~s|{"Temperature":-1,"Environment Light":-1}|)
        end do
        assert :asleep == Fetch.fetch_status("", :http)
      end
    end

    test ~s|returns {:up, temp} when response body has `"Temperature": temp` where temp != -1| do
      with_mock HTTPoison, get: fn _, _, _ -> httpoison_ok(~s|{"Temperature":42}|) end do
        assert {:up, 42} == Fetch.fetch_status("", :http)
      end
    end

    test "returns {:up, temp} when temperature is -1 C as long as environment light is not -1" do
      with_mock HTTPoison,
        get: fn _, _, _ -> httpoison_ok(~s|{"Temperature":-1,"Environment Light":180}|) end do
        assert {:up, -1} == Fetch.fetch_status("", :http)
      end
    end

    test "returns {:connection_error, <switch ping result>} when request failed" do
      with_mocks [
        {HTTPoison, [], get: fn _, _, _ -> {:error, :reason} end},
        {Ping, [], switch_pingable?: fn _ -> true end}
      ] do
        assert {:connection_error, true} == Fetch.fetch_status("", :http)
      end
    end

    test "returns {:bad_status, <status>} when a non-200 response was received" do
      with_mock HTTPoison, get: fn _, _, _ -> httpoison_ok("", 404) end do
        assert {:bad_status, 404} == Fetch.fetch_status("", :http)
      end
    end

    test "returns :invalid_response when an unexpected response body was received" do
      with_mock HTTPoison, get: fn _, _, _ -> httpoison_ok(~s|{"SomethingElse":true}|) end do
        assert :invalid_response == Fetch.fetch_status("", :http)
      end
    end

    test "returns :error in all other cases" do
      with_mock HTTPoison, get: fn _, _, _ -> :something_else end do
        assert :error == Fetch.fetch_status("", :http)
      end
    end
  end

  defp httpoison_ok(body, status_code \\ 200) do
    {:ok, %{status_code: status_code, body: body}}
  end
end
