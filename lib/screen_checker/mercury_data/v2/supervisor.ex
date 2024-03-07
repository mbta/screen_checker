defmodule ScreenChecker.MercuryData.V2.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link([]) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      {ScreenChecker.MercuryData.V2.State, [name: ScreenChecker.MercuryData.V2.State]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
