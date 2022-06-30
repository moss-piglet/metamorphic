defmodule Metamorphic.Billing.HandleSubscriptions do
  @moduledoc """
  Stripe HandleSubscriptions context.
  """
  alias Metamorphic.Billing.Plans
  alias Metamorphic.Billing.Customers
  alias Metamorphic.Billing.Subscriptions

  defdelegate get_customer_by_stripe_id!(customer_stripe_id), to: Customers
  defdelegate get_plan_by_stripe_id!(plan_stripe_id), to: Plans
  defdelegate get_subscription_by_stripe_id!(subscription_stripe_id), to: Subscriptions
  defdelegate get_subscription_by_stripe_id(subscription_stripe_id), to: Subscriptions

  def create_subscription(
        %{customer: customer_stripe_id, plan: %{id: plan_stripe_id}} = stripe_subscription
      ) do
    customer = get_customer_by_stripe_id!(customer_stripe_id)
    plan = get_plan_by_stripe_id!(plan_stripe_id)
    customer_stripe_subscriptions = Subscriptions.safe_list_subscriptions(customer)

    # We only want to create a subscription if customer doesn't already have one.
    # This handles failed webhooks that are being re-sent by stripe.
    if Enum.empty?(customer_stripe_subscriptions) do
      Subscriptions.create_subscription(plan, customer, %{
        stripe_id: stripe_subscription.id,
        status: stripe_subscription.status,
        current_period_end_at: unix_to_naive_datetime(stripe_subscription.current_period_end),
        trial_end_at: unix_to_naive_datetime(stripe_subscription.trial_end)
      })
    end
  end

  def update_subscription(
        %{customer: customer_stripe_id, plan: %{id: plan_stripe_id}, status: status} =
          stripe_subscription
      ) do
    customer = get_customer_by_stripe_id!(customer_stripe_id)
    plan = get_plan_by_stripe_id!(plan_stripe_id)
    subscription = get_subscription_by_stripe_id(stripe_subscription.id)

    if status === "active" do
      # Set the Customer record free_trial to true to indicate the
      # customer has used their 1-free trial.
      case Customers.update_customer(customer, %{free_trial: true}) do
        {:ok, _customer} ->
          Subscriptions.update_subscription(subscription, plan, customer, %{
            stripe_id: stripe_subscription.id,
            status: stripe_subscription.status,
            current_period_end_at: unix_to_naive_datetime(stripe_subscription.current_period_end),
            trial_end_at: unix_to_naive_datetime(stripe_subscription.trial_end)
          })

        {:error, _changeset} ->
          Subscriptions.update_subscription(subscription, plan, customer, %{
            stripe_id: stripe_subscription.id,
            status: stripe_subscription.status,
            current_period_end_at: unix_to_naive_datetime(stripe_subscription.current_period_end),
            trial_end_at: unix_to_naive_datetime(stripe_subscription.trial_end)
          })
      end
    else
      Subscriptions.update_subscription(subscription, plan, customer, %{
        stripe_id: stripe_subscription.id,
        status: stripe_subscription.status,
        current_period_end_at: unix_to_naive_datetime(stripe_subscription.current_period_end),
        trial_end_at: unix_to_naive_datetime(stripe_subscription.trial_end)
      })
    end
  end

  @doc """
  Handles canceling a subscription, including `customer.subscription.deleted`
  webhook from Stripe that comes after the database has already deleted
  the Subscription.
  """
  def cancel_subscription(%{id: stripe_id} = stripe_subscription) do
    case get_subscription_by_stripe_id(stripe_id) do
      nil ->
        nil

      subscription ->
        cancel_at = stripe_subscription.cancel_at || stripe_subscription.canceled_at

        Subscriptions.cancel_subscription(subscription, %{
          status: stripe_subscription.status,
          cancel_at: unix_to_naive_datetime(cancel_at)
        })
    end
  end

  defp unix_to_naive_datetime(nil), do: nil

  defp unix_to_naive_datetime(datetime_in_seconds) do
    datetime_in_seconds
    |> DateTime.from_unix!()
    |> DateTime.to_naive()
  end
end
