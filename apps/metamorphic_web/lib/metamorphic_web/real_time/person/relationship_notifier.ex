defmodule MetamorphicWeb.RealTime.Person.RelationshipNotifier do
  @moduledoc """
  RelationshipNotifier PubSub module for people to
  subscribe and broadcast relationship notifications.
  """

  @topic "person:relationship_notifier:*"

  def subscribe(current_person) do
    Phoenix.PubSub.subscribe(MetamorphicWeb.PubSub, @topic <> "#{current_person.id}")
  end

  def broadcast_create_relationship(relationship, person, requesting_person) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic <> "#{person.id}",
      {:create_relationship, {relationship, requesting_person}}
    )

    {:ok, relationship}
  end
end
