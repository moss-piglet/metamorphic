defmodule Metamorphic.Workers.StripeWebhooksSubscriptionWorker do
  @moduledoc """
  Oban worker for new subscriptions to Stripe.
  """
  use Oban.Worker, queue: :events, unique: [period: 60]

  alias Metamorphic.Accounts
  alias Metamorphic.Billing

  @stripe_service Application.compile_env(:metamorphic, :stripe_service)
  @two_week_free_trial 14

  def perform(%Oban.Job{
        args: %{
          "customer_stripe_id" => customer_stripe_id,
          "price_stripe_id" => price_stripe_id,
          "free_trial" => free_trial,
          "current_person_id" => current_person_id
        }
      }) do
    if free_trial do
      # If the customer has already had a free_trial
      {:ok, subscription} =
        @stripe_service.Subscription.create(%{
          customer: customer_stripe_id,
          items: [%{price: price_stripe_id}]
        })

      {:ok, invoice} = @stripe_service.Invoice.retrieve(subscription.latest_invoice)
      {:ok, _customer} = @stripe_service.Customer.retrieve(invoice.customer)

      :ok
    else
      current_person = Accounts.get_person!(current_person_id)
      customer = Billing.get_billing_customer_for_person(current_person)

      {:ok, subscription} =
        @stripe_service.Subscription.create(%{
          customer: customer.stripe_id,
          items: [%{price: price_stripe_id}],
          trial_period_days: @two_week_free_trial
        })

      Billing.Customers.update_customer(customer, %{"free_trial" => true})
      {:ok, invoice} = @stripe_service.Invoice.retrieve(subscription.latest_invoice)
      {:ok, _customer} = @stripe_service.Customer.retrieve(invoice.customer)

      :ok
    end
  end
end
