defmodule MetamorphicWeb.StripeHandler do
  @moduledoc false
  @behaviour Stripe.WebhookHandler

  @impl true
  def handle_event(event) do
    notify_subscribers(event)
  end

  def notify_subscribers(event) do
    Phoenix.PubSub.broadcast(MetamorphicWeb.PubSub, "webhook_received", %{event: event})
  end

  def subscribe_on_webhook_received() do
    Phoenix.PubSub.subscribe(MetamorphicWeb.PubSub, "webhook_received")
  end
end
