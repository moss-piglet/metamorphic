defmodule MetamorphicWeb.RealTime.Person.TOTP do
  @moduledoc """
  TOTP PubSub module for people to
  subscribe and broadcast updates for the
  PersonSettings `index.ex`.
  """

  @topic "person:totp:*"

  def subscribe(current_person) do
    Phoenix.PubSub.subscribe(MetamorphicWeb.PubSub, @topic <> "#{current_person.id}")
  end

  def broadcast_update_totp(totp, current_person) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic <> "#{current_person.id}",
      {:update_totp, totp}
    )

    {:ok, totp}
  end

  def broadcast_update_totp_description(totp, current_person) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic <> "#{current_person.id}",
      {:update_totp_description, totp}
    )

    {:ok, totp}
  end

  def broadcast_save_totp(totp, current_person) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic <> "#{current_person.id}",
      {:save_totp, totp}
    )

    {:ok, totp}
  end

  def broadcast_delete_totp(totp, current_person) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic <> "#{current_person.id}",
      {:delete_totp, totp}
    )

    {:ok, totp}
  end
end
