defmodule MetamorphicWeb.RealTime.Person.SubscriptionNotifier do
  @moduledoc """
  `SubscriptionNotifier` PubSub module for people to
  subscribe and broadcast subscription notifications.
  """

  @topic "person:subscription_notifier:*"

  def subscribe(current_person) do
    Phoenix.PubSub.subscribe(
      MetamorphicWeb.PubSub,
      @topic <> "#{current_person.billing_customer.stripe_id}"
    )
  end

  def broadcast_create_subscription(subscription, customer_id) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic <> "#{customer_id}",
      {:create_subscription, subscription}
    )

    {:ok, subscription}
  end
end
