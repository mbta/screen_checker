defmodule ScreenChecker.MercuryData.V2.Logger do
  @moduledoc false

  alias ScreenChecker.MercuryData.V2.Fetch
  alias ScreenChecker.VendorData.Logger, as: VendorLogger

  def log_data(since) do
    VendorLogger.log_data(
      fn -> Fetch.fetch_data(since) end,
      :mercury_v2,
      "MERCURY_V2_API_KEY"
    )
  end
end
