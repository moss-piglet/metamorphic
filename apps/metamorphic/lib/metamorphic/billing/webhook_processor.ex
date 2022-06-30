defmodule Metamorphic.Billing.WebhookProcessor do
  @moduledoc """
  A GenServer to process the Stripe event payload
  asynchronously with the Stripe webhook endpoint.
  """
  use GenServer

  alias MetamorphicWeb.StripeHandler
  alias Metamorphic.Billing.SynchronizeProducts
  alias Metamorphic.Billing.SynchronizePlans
  alias Metamorphic.Billing.{HandleCustomers, HandleSubscriptions}
  alias MetamorphicWeb.RealTime

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(state) do
    StripeHandler.subscribe_on_webhook_received()
    {:ok, state}
  end

  def handle_info(%{event: event}, state) do
    notify_subscribers(event)

    case event.type do
      "product.created" ->
        SynchronizeProducts.run()
        SynchronizePlans.run()

      "product.updated" ->
        SynchronizeProducts.run()
        SynchronizePlans.run()

      "product.deleted" ->
        SynchronizeProducts.run()
        SynchronizePlans.run()

      "plan.created" ->
        SynchronizePlans.run()

      "plan.updated" ->
        SynchronizePlans.run()

      "plan.deleted" ->
        SynchronizePlans.run()

      "customer.updated" ->
        nil

      "customer.deleted" ->
        nil

      "customer.discount.created" ->
        RealTime.Person.Stripe.broadcast_customer_discount_created(event.data.object)

      # RealTime.Person.Stripe.broadcast_customer_discount_updated(event.data.object)
      "customer.discount.updated" ->
        nil

      "customer.discount.deleted" ->
        RealTime.Person.Stripe.broadcast_customer_discount_deleted(event.data.object)

      "customer.subscription.updated" ->
        HandleSubscriptions.update_subscription(event.data.object)

      "customer.subscription.deleted" ->
        HandleSubscriptions.cancel_subscription(event.data.object)

      "customer.subscription.created" ->
        HandleSubscriptions.create_subscription(event.data.object)

      _ ->
        nil
    end

    {:noreply, state}
  end

  def subscribe do
    Phoenix.PubSub.subscribe(MetamorphicWeb.PubSub, "webhook_processed")
  end

  def notify_subscribers(event) do
    Phoenix.PubSub.broadcast(MetamorphicWeb.PubSub, "webhook_processed", {:event, event})
  end

  defmodule Stub do
    use GenServer
    def start_link(_), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)
    def init(state), do: {:ok, state}
  end
end
