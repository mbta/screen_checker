defmodule ScreenChecker.TimeTest do
  use ExUnit.Case

  describe "next_minute_ms/1" do
    test "returns 60_000 when passed a DateTime at the start of a minute" do
      high_noon_in_boston = ~U[2020-08-14 16:00:00Z]
      assert 60_000 == ScreenChecker.Time.next_minute_ms(high_noon_in_boston)
    end

    test "returns milliseconds to next minute" do
      dt = ~U[2020-08-14 16:05:15.5007Z]
      assert 44_500 == ScreenChecker.Time.next_minute_ms(dt)
    end
  end
end
