defmodule MetamorphicWeb.RealTime.Person.Portal do
  @moduledoc """
  Portal PubSub module for people to
  subscribe and broadcast updates for portals.
  """

  @topic "person:portals:*"

  def subscribe(current_person) do
    Phoenix.PubSub.subscribe(MetamorphicWeb.PubSub, @topic <> "#{current_person.id}")
    Phoenix.PubSub.subscribe(MetamorphicWeb.PubSub, @topic <> "delete")
  end

  def broadcast_create_portal(portal, current_person_id) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic <> current_person_id,
      {:create_portal, portal}
    )

    {:ok, portal}
  end

  def broadcast_delete_portal(portal) do
    Phoenix.PubSub.broadcast!(MetamorphicWeb.PubSub, @topic <> "delete", {:delete_portal, portal})

    {:ok, portal}
  end
end
