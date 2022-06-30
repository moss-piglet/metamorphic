defmodule MetamorphicWeb.RealTime.Person.FavoriteMemory do
  @moduledoc """
  Favorite Memory PubSub module for people to
  subscribe and broadcast updates for favoriting
  memories in the Memory `index.ex`.
  """

  @topic "person:favorite_memory:*"

  def subscribe(current_person) do
    Phoenix.PubSub.subscribe(MetamorphicWeb.PubSub, @topic <> "#{current_person.id}")
  end

  def broadcast_update_favorite_memory(memory, current_person) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic <> "#{current_person.id}",
      {:update_favorite_memory, memory}
    )

    {:ok, memory}
  end

  def broadcast_update_favorite_memory_after_favorite(memory, current_person) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic <> "#{current_person.id}",
      {:update_favorite_memory_after_favorite, memory}
    )

    {:ok, memory}
  end

  def broadcast_update_shared_memory(shared_memory, current_person) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic <> "#{current_person.id}",
      {:update_shared_memory, shared_memory}
    )

    {:ok, shared_memory}
  end

  def broadcast_update_favorite_shared_memory(shared_memory, current_person) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic <> "#{current_person.id}",
      {:update_favorite_shared_memory, shared_memory}
    )

    {:ok, shared_memory}
  end
end
