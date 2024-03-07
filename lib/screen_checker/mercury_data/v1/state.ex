defmodule ScreenChecker.MercuryData.V1.State do
  @moduledoc false

  alias ScreenChecker.MercuryData.V1.Logger, as: MercuryLoggerV1

  use ScreenChecker.VendorData.State

  def do_log do
    MercuryLoggerV1.log_data()
    :ok
  end
end
