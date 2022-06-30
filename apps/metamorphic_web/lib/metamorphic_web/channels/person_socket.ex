defmodule MetamorphicWeb.PersonSocket do
  use Phoenix.Socket

  ## Channels
  # channel "room:*", MetamorphicWeb.RoomChannel

  # Socket params are passed from the client and can
  # be used to verify and authenticate a person. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :person_id, verified_person_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  @impl true
  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  # Socket id's are topics that allow you to identify all sockets for a given person:
  #
  #     def id(socket), do: "person_socket:#{socket.assigns.person_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given person:
  #
  #     MetamorphicWeb.Endpoint.broadcast("person_socket:#{person.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl true
  def id(_socket), do: nil
end
