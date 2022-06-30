defmodule MetamorphicWeb.RealTime.Person.Memory do
  @moduledoc """
  Memory PubSub module for people to
  subscribe and broadcast updates for the
  Memory `index.ex`.
  """

  @topic "person:memory"

  def subscribe do
    Phoenix.PubSub.subscribe(MetamorphicWeb.PubSub, @topic)
  end

  def broadcast_update_memory(memory) do
    Phoenix.PubSub.broadcast!(MetamorphicWeb.PubSub, @topic, {:update_memory, memory})

    {:ok, memory}
  end

  def broadcast_update_memory_description(memory) do
    Phoenix.PubSub.broadcast!(MetamorphicWeb.PubSub, @topic, {:update_memory_description, memory})

    {:ok, memory}
  end

  def broadcast_share_memory(memory) do
    Phoenix.PubSub.broadcast!(MetamorphicWeb.PubSub, @topic, {:share_memory, memory})

    {:ok, memory}
  end

  def broadcast_save_memory(memory) do
    Phoenix.PubSub.broadcast!(MetamorphicWeb.PubSub, @topic, {:save_memory, memory})

    {:ok, memory}
  end

  def broadcast_delete_memory(memory) do
    Phoenix.PubSub.broadcast!(MetamorphicWeb.PubSub, @topic, {:delete_memory, memory})

    {:ok, memory}
  end

  def broadcast_delete_shared_memory(shared_memory) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic,
      {:delete_shared_memory, shared_memory}
    )

    {:ok, shared_memory}
  end
end
