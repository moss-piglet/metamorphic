defmodule MetamorphicWeb.RealTime.Admin.Invitation do
  @moduledoc """
  Invitation PubSub module for admins to
  subscribe and broadcast updates for the
  Invite `index.ex`.
  """

  @topic "admin:invitation"

  def subscribe do
    Phoenix.PubSub.subscribe(MetamorphicWeb.PubSub, @topic)
  end

  def broadcast_update_invitation(invite) do
    Phoenix.PubSub.broadcast!(MetamorphicWeb.PubSub, @topic, {:update_invitation, invite})
  end

  def broadcast_save_invitation(invite) do
    Phoenix.PubSub.broadcast!(MetamorphicWeb.PubSub, @topic, {:save_invitation, invite})
  end

  def broadcast_delete_invitation(id) do
    Phoenix.PubSub.broadcast!(MetamorphicWeb.PubSub, @topic, {:delete_invitation, id})
  end
end
