defmodule MetamorphicWeb.RealTime.Person.SharedAvatar do
  @moduledoc """
  SharedAvatar PubSub module for people to
  subscribe and broadcast updates.
  """

  @topic "person:shared_avatar"

  def subscribe() do
    Phoenix.PubSub.subscribe(MetamorphicWeb.PubSub, @topic)
  end

  def broadcast_update_shared_avatar(shared_avatar) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic,
      {:update_shared_avatar, shared_avatar}
    )

    {:ok, shared_avatar}
  end

  def broadcast_delete_shared_avatar(shared_avatar) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic,
      {:delete_shared_avatar, shared_avatar}
    )

    {:ok, shared_avatar}
  end

  def broadcast_delete_shared_avatar_from_account_settings(pid, shared_avatar) do
    Phoenix.PubSub.broadcast_from!(
      MetamorphicWeb.PubSub,
      pid,
      @topic,
      {:delete_shared_avatar, shared_avatar}
    )

    {:ok, shared_avatar}
  end
end
