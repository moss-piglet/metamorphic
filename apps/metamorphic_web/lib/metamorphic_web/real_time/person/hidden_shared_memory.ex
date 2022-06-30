defmodule MetamorphicWeb.RealTime.Person.HiddenSharedMemory do
  @moduledoc """
  Hidden Shared Memory PubSub module for people to
  subscribe and broadcast updates for hiding/revealing
  shared_memories in the Memory `index.ex`.
  """

  @topic "person:hidden_shared_memory:*"

  def subscribe(current_person) do
    Phoenix.PubSub.subscribe(MetamorphicWeb.PubSub, @topic <> "#{current_person.id}")
  end

  def broadcast_update_shared_memory_hide(shared_memory, current_person) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic <> "#{current_person.id}",
      {:update_shared_memory_hide_or_reveal, shared_memory}
    )

    {:ok, shared_memory}
  end

  def broadcast_update_shared_memory_reveal(shared_memory, current_person) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic <> "#{current_person.id}",
      {:update_shared_memory_hide_or_reveal, shared_memory}
    )

    {:ok, shared_memory}
  end
end
