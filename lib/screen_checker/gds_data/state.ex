defmodule ScreenChecker.GdsData.State do
  @moduledoc false

  alias ScreenChecker.GdsData.Logger, as: GdsLogger

  use ScreenChecker.VendorData.State

  def do_log do
    GdsLogger.log_data()
    :ok
  end
end
