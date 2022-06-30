defmodule MetamorphicWeb.RealTime.Person.DeleteAccount do
  @moduledoc """
  `DeleteAccount` PubSub module for people to
  subscribe and broadcast updates.

  Currently used for broadcasting when a
  `Person` deletes their account.
  """

  @topic "person:delete_account"

  def subscribe() do
    Phoenix.PubSub.subscribe(MetamorphicWeb.PubSub, @topic)
  end

  def broadcast_delete_account(person) do
    Phoenix.PubSub.broadcast!(MetamorphicWeb.PubSub, @topic, {:delete_account, person})

    {:ok, person}
  end
end
