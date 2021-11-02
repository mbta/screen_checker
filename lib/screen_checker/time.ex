defmodule ScreenChecker.Time do
  @moduledoc false

  @doc "Milliseconds to wait until the start of the next minute"
  @spec next_minute_ms(DateTime.t()) :: non_neg_integer()
  def next_minute_ms(dt \\ DateTime.utc_now()) do
    {microsecond, _} = dt.microsecond
    current_ms = dt.second * 1000 + div(microsecond, 1000)
    60 * 1000 - current_ms
  end
end
