defmodule MetamorphicWeb.RealTime.Person.HiddenMemory do
  @moduledoc """
  Hidden Memory PubSub module for people to
  subscribe and broadcast updates for hiding/revealing
  memories in the Memory `index.ex`.
  """

  @topic "person:hidden_memory:*"

  def subscribe(current_person) do
    Phoenix.PubSub.subscribe(MetamorphicWeb.PubSub, @topic <> "#{current_person.id}")
  end

  def broadcast_update_memory_hide(memory, current_person) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic <> "#{current_person.id}",
      {:update_memory_hide, memory}
    )

    {:ok, memory}
  end

  def broadcast_update_memory_reveal(memory, current_person) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic <> "#{current_person.id}",
      {:update_memory_reveal, memory}
    )

    {:ok, memory}
  end
end
