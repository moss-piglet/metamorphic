defmodule MetamorphicWeb.Stun do
  @moduledoc """
  A STUN server for Metamorphic's portals.

  Uses Elixir GenServer to create a localhost
  STUN server during development. The production
  STUN server is set in the `prod.exs` configuration.
  """
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  @impl true
  @doc """
  Starts the erlang stun server at port 3478.
  """
  def init(_) do
    :stun_listener.add_listener({127, 0, 0, 1}, 3478, :udp, [])

    {:ok, []}
  end
end
