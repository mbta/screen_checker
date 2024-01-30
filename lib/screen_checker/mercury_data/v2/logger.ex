defmodule ScreenChecker.MercuryData.V2.Logger do
  @moduledoc false

  alias ScreenChecker.MercuryData.V2.Fetch
  alias ScreenChecker.VendorData.Logger, as: VendorLogger

  def log_data do
    VendorLogger.log_data(
      &Fetch.fetch_data/0,
      :mercury_v2,
      "MERCURY_V2_API_KEY"
    )
  end
end
