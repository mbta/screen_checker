defmodule ScreenChecker.MercuryData.V2.State do
  @moduledoc false

  alias ScreenChecker.MercuryData.V2.Logger, as: MercuryLoggerV2

  use ScreenChecker.VendorData.State

  def do_log(since) do
    MercuryLoggerV2.log_data(since)
    :ok
  end
end
