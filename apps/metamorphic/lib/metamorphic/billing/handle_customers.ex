defmodule Metamorphic.Billing.HandleCustomers do
  @moduledoc """
  Stripe `HandleCustomers` context.
  """
  alias Metamorphic.Accounts
  alias Metamorphic.Accounts.Person
  alias Metamorphic.Billing.Plans
  alias Metamorphic.Billing.Customers
  alias Metamorphic.Billing.Subscriptions

  # defdelegate get_customer_by_stripe_id!(customer_stripe_id), to: Customers
  # defdelegate get_plan_by_stripe_id!(plan_stripe_id), to: Plans
  # defdelegate get_subscription_by_stripe_id!(subscription_stripe_id), to: Subscriptions
  # defdelegate get_subscription_by_stripe_id(subscription_stripe_id), to: Subscriptions

  def update_customer(
        %{id: customer_stripe_id, default_source: default_source, email: stripe_email} =
          stripe_customer
      ) do
    person = Accounts.get_person_by_email(stripe_email)
    customer = Customers.get_customer_by_stripe_id(customer_stripe_id)

    cond do
      person != nil && is_nil(customer) ->
        Customers.create_customer(person, %{
          stripe_id: customer_stripe_id,
          default_source: default_source
        })

      person != nil && customer != nil ->
        Customers.update_customer(customer, %{
          stripe_id: customer_stripe_id,
          default_source: default_source
        })

      is_nil(person) && is_nil(customer) ->
        nil
    end
  end
end
