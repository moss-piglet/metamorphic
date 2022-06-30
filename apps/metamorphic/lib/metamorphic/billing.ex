defmodule Metamorphic.Billing do
  @moduledoc """
  The Billing context.
  """

  import Ecto.Query, warn: false
  alias Metamorphic.Billing.Products
  alias Metamorphic.Billing.Plans
  alias Metamorphic.Billing.Customers
  alias Metamorphic.Billing.Subscriptions

  defdelegate list_products(), to: Products
  defdelegate with_plans(product_or_products), to: Products
  defdelegate create_product(attrs), to: Products

  defdelegate get_plan!(plan_id), to: Plans
  defdelegate create_plan(product, attrs), to: Plans
  defdelegate list_plans_for_subscription_page, to: Plans

  defdelegate get_billing_customer_for_person(person), to: Customers

  defdelegate get_active_subscription_for_person(id), to: Subscriptions
  defdelegate update_current_stripe_subscription(current_subscription), to: Subscriptions
  defdelegate get_active_or_trial_subscription_for_person(id), to: Subscriptions
  defdelegate get_trial_subscription_for_person(id), to: Subscriptions
  defdelegate safe_download_list_subscription_data(current_customer), to: Subscriptions
end
