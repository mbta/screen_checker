defmodule ScreenChecker.GdsData.Logger do
  @moduledoc false

  alias ScreenChecker.GdsData.Fetch
  alias ScreenChecker.VendorData.Logger, as: VendorLogger

  def log_data do
    VendorLogger.log_data(
      &Fetch.fetch_data_for_current_day/0,
      :gds,
      :gds_dms_password
    )
  end
end
