defmodule ScreenChecker.MercuryData.State do
  @moduledoc false

  alias ScreenChecker.MercuryData.Logger, as: MercuryLogger

  use ScreenChecker.VendorData.State

  def do_log do
    MercuryLogger.log_data()
    :ok
  end
end
