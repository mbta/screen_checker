defmodule ScreenChecker.MercuryData.V1.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link([]) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      {ScreenChecker.MercuryData.V1.State, [name: ScreenChecker.MercuryData.V1.State]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
