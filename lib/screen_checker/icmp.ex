defmodule ScreenChecker.ICMP do
  @moduledoc """
  Basic ICMP ping client, copied from https://elixirforum.com/t/zing-basic-elixir-icmp-ping-server-using-zig-nif/31681/3

  ## Examples

      iex> ScreenChecker.ICMP.ping("172.19.43.25")
      {:ok, %{data: <<222, 173, 190, 239>>, id: 0, seq: 0}}

      iex> ScreenChecker.ICMP.ping({172, 19, 43, 25})
      {:ok, %{data: <<222, 173, 190, 239>>, id: 0, seq: 0}}

      iex> ScreenChecker.ICMP.ping({1, 2, 3, 4})
      {:error,
       %{
         data: <<5, 103, 95, 96, 209, 186, 0, 14, 182, 28, 8, 9, 10, 11, 12, 13, 14,
           15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33,
           34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, ...>>,
         id: 217,
         seq: 14
       }}
  """

  @data <<0xDEADBEEF::size(32)>>

  def ping(addr) when is_binary(addr) do
    addr
    |> String.split(".")
    |> Enum.map(&String.to_integer/1)
    |> (fn [a, b, c, d] -> {a, b, c, d} end).()
    |> ping()
  end

  def ping(addr) when is_tuple(addr) and tuple_size(addr) == 4 do
    {:ok, s} = open()

    data = @data

    req_echo(s, addr, data: data)

    case recv_echo(s) do
      {:ok, %{data: ^data}} = resp -> resp
      {:ok, other} -> {:error, other}
      _ -> {:error, :invalid_resp}
    end
  end

  defp open, do: :socket.open(:inet, :dgram, :icmp)

  defp req_echo(socket, addr, opts) do
    data = Keyword.get(opts, :data, @data)
    id = Keyword.get(opts, :id, 0)
    seq = Keyword.get(opts, :seq, 0)

    sum = checksum(<<8, 0, 0::size(16), id, seq, data::binary>>)

    msg = <<8, 0, sum::binary, id, seq, data::binary>>

    :socket.sendto(socket, msg, %{family: :inet, port: 1, addr: addr})
  end

  defp recv_echo(socket, timeout \\ 5000) do
    {:ok, data} = :socket.recv(socket, 0, [], timeout)

    <<_::size(160), pong::binary>> = data

    case pong do
      <<0, 0, _::size(16), id, seq, data::binary>> ->
        {:ok,
         %{
           id: id,
           seq: seq,
           data: data
         }}

      _ ->
        {:error, pong}
    end
  end

  defp checksum(bin), do: checksum(bin, 0)

  defp checksum(<<x::integer-size(16), rest::binary>>, sum), do: checksum(rest, sum + x)
  defp checksum(<<x>>, sum), do: checksum(<<>>, sum + x)

  defp checksum(<<>>, sum) do
    <<x::size(16), y::size(16)>> = <<sum::size(32)>>

    res = :erlang.bnot(x + y)

    <<res::big-size(16)>>
  end
end
