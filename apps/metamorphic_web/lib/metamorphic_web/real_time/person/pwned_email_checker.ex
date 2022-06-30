defmodule MetamorphicWeb.RealTime.Person.PwnedEmailChecker do
  @moduledoc """
  PwnedEmailChecker PubSub module for people to
  subscribe and broadcast updates for the
  PersonSettingsLive `index.ex`.
  """

  @topic "person:pwned_email_checker:*"

  def subscribe(current_person) do
    Phoenix.PubSub.subscribe(MetamorphicWeb.PubSub, @topic <> "#{current_person.id}")
  end

  def broadcast_check_if_email_pwned(current_person, pwned_key, pwned_message) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic <> "#{current_person.id}",
      {:pwned_email_checker, pwned_key, pwned_message}
    )

    {:ok, current_person}
  end
end
