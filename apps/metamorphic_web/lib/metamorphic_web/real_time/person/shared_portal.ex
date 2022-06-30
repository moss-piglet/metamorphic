defmodule MetamorphicWeb.RealTime.Person.SharedPortal do
  @moduledoc """
  SharedPortal PubSub module for people to
  subscribe and broadcast updates for portals.
  """

  @topic "person:shared_portal:*"

  def subscribe(current_person) do
    Phoenix.PubSub.subscribe(MetamorphicWeb.PubSub, @topic <> "#{current_person.id}")
  end

  def broadcast_create_shared_portal(shared_portal, person_id, current_person_id) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic <> person_id,
      {:create_shared_portal, shared_portal}
    )

    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic <> current_person_id,
      {:create_shared_portal, shared_portal}
    )

    {:ok, shared_portal}
  end

  def broadcast_delete_shared_portal(shared_portal, person_id, current_person_id) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic <> person_id,
      {:delete_shared_portal, shared_portal}
    )

    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic <> current_person_id,
      {:delete_shared_portal, shared_portal}
    )

    {:ok, shared_portal}
  end
end
