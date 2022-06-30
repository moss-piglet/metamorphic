defmodule MetamorphicWeb.AuthSocket do
  use Phoenix.Socket
  require Logger

  channel "person:*", MetamorphicWeb.AuthChannel

  @one_day 86_400

  @impl true
  def connect(%{"token" => token}, socket) do
    case verify(socket, token) do
      {:ok, person_id} ->
        socket = assign(socket, :person_id, person_id)
        {:ok, socket}

      {:error, err} ->
        Logger.error("#{__MODULE__} connect error #{inspect(err)}")
        :error
    end
  end

  @impl true
  def connect(_, _socket) do
    Logger.error("#{__MODULE__} connect error missing params")
    :error
  end

  defp verify(socket, token),
    do: Phoenix.Token.verify(socket, "salt identifier", token, max_age: @one_day)

  @impl true
  def id(%{assigns: %{person_id: person_id}}), do: "auth_socket:#{person_id}"
end
