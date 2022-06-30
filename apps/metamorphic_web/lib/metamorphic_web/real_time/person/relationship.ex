defmodule MetamorphicWeb.RealTime.Person.Relationship do
  @moduledoc """
  Relationship PubSub module for people to
  subscribe and broadcast updates.
  """
  alias Metamorphic.Relationships.Relationship

  @topic "person:relationship"

  def subscribe() do
    Phoenix.PubSub.subscribe(MetamorphicWeb.PubSub, @topic)
  end

  def broadcast_save_relationship(relationship) do
    Phoenix.PubSub.broadcast!(MetamorphicWeb.PubSub, @topic, {:save_relationship, relationship})

    {:ok, relationship}
  end

  def broadcast_update_relationship(relationship) do
    case relationship do
      %Relationship{} = relationship ->
        Phoenix.PubSub.broadcast!(
          MetamorphicWeb.PubSub,
          @topic,
          {:update_relationship, relationship}
        )

        {:ok, relationship}

      {:ok, %Relationship{} = relationship} ->
        Phoenix.PubSub.broadcast!(
          MetamorphicWeb.PubSub,
          @topic,
          {:update_relationship, relationship}
        )

        {:ok, relationship}
    end
  end

  def broadcast_delete_relationship(relationship) do
    Phoenix.PubSub.broadcast!(MetamorphicWeb.PubSub, @topic, {:delete_relationship, relationship})

    {:ok, relationship}
  end
end
