defmodule MetamorphicWeb.RealTime.Admin.Announcement do
  @moduledoc """
  Announcement PubSub module for admins to
  subscribe and broadcast updates for announcements.
  """

  @topic "admin:announcements"

  def subscribe do
    Phoenix.PubSub.subscribe(MetamorphicWeb.PubSub, @topic)
  end

  def broadcast_update_announcement(announcement) do
    Phoenix.PubSub.broadcast!(MetamorphicWeb.PubSub, @topic, {:update_announcement, announcement})

    {:ok, announcement}
  end

  def broadcast_save_announcement(announcement) do
    Phoenix.PubSub.broadcast!(MetamorphicWeb.PubSub, @topic, {:save_announcement, announcement})

    {:ok, announcement}
  end

  def broadcast_delete_announcement(id) do
    Phoenix.PubSub.broadcast!(MetamorphicWeb.PubSub, @topic, {:delete_announcement, id})

    {:ok, id}
  end
end
