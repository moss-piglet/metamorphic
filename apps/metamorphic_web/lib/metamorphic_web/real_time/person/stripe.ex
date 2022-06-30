defmodule MetamorphicWeb.RealTime.Person.Stripe do
  @moduledoc """
  PubSub for broadcasting Stripe events to
  the current_person/current_customer.
  """

  @topic "person:stripe:*"

  def subscribe(current_customer) do
    unless is_nil(current_customer) do
      Phoenix.PubSub.subscribe(MetamorphicWeb.PubSub, @topic <> "#{current_customer.stripe_id}")
    end
  end

  def broadcast_customer_discount_created(stripe_object) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic <> "#{stripe_object.customer}",
      {:stripe_customer_discount_created, stripe_object}
    )
  end

  def broadcast_customer_discount_updated(_stripe_object), do: nil

  def broadcast_customer_discount_deleted(stripe_object) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic <> "#{stripe_object.customer}",
      {:stripe_customer_discount_deleted, stripe_object}
    )
  end
end
