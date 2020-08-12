defmodule ScreenChecker.Screen do
  @enforce_keys [:ip, :name]
  defstruct ip: nil,
            name: nil,
            status: :up

  def set_status(%__MODULE__{status: current} = screen, new) when current == new do
    {:ok, screen}
  end

  def set_status(%__MODULE__{} = screen, status) do
    {:updated, %{screen | status: status}}
  end
end
