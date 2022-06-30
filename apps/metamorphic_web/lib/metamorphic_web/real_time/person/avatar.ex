defmodule MetamorphicWeb.RealTime.Person.Avatar do
  @moduledoc """
  Avatar PubSub module for people to
  subscribe and broadcast updates for the
  PersonSettingsLive `index.ex`.
  """

  @topic "person:avatar:*"

  def subscribe(current_person) do
    Phoenix.PubSub.subscribe(MetamorphicWeb.PubSub, @topic <> "#{current_person.id}")
  end

  def broadcast_update_avatar(person, current_person) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic <> "#{current_person.id}",
      {:update_avatar, person}
    )

    {:ok, person}
  end

  def broadcast_delete_avatar(person, current_person) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic <> "#{current_person.id}",
      {:delete_avatar, person}
    )

    {:ok, person}
  end
end
