defmodule ScreenChecker.MercuryData.V1.Logger do
  @moduledoc false

  alias ScreenChecker.MercuryData.V1.Fetch
  alias ScreenChecker.VendorData.Logger, as: VendorLogger

  def log_data do
    VendorLogger.log_data(
      &Fetch.fetch_data/0,
      :mercury,
      "MERCURY_API_KEY"
    )
  end
end
