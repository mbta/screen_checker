defmodule ScreenChecker.Ping do
  @moduledoc false

  def switch_pingable?(screen_ip) do
    screen_ip
    |> screen_ip_to_switch_ip()
    |> ping_once()
    |> case do
      {_, 0} -> true
      _ -> false
    end
  end

  def screen_ip_to_switch_ip(ip) do
    String.replace(ip, ~r|\.\d+$|, ".1")
  end

  defp ping_once(ip) do
    cmd_args =
      case :os.type() do
        {:win32, _} -> ~w[-n 1 #{ip}]
        {:unix, _} -> ~w[-c 1 #{ip}]
      end

    System.cmd("ping", cmd_args, stderr_to_stdout: true)
  end
end
