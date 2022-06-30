defmodule MockStripe.Plan do
  @moduledoc """
  Module for setting up fake data to
  mimic Stripe data for mocking tests.

  This mimics the Stripe Plan struct.
  """
  defstruct [
    :active,
    :amount,
    :amount_decimal,
    :currency,
    :deleted,
    :id,
    :interval,
    :interval_count,
    :name,
    :nickname,
    :object,
    :product,
    :usage_type
  ]

  alias MockStripe.List
  alias MockStripe.Plan

  def retrieve() do
    stripe_id = "price_#{MockStripe.token()}"
    retrieve(stripe_id)
  end

  def retrieve("price_" <> _ = stripe_id) do
    %Plan{
      active: true,
      amount: 14000,
      amount_decimal: "14000",
      currency: "usd",
      id: stripe_id,
      interval: "year",
      interval_count: "1",
      nickname: "Metamorphic member pricing plan",
      object: "plan",
      product: "prod_JZJra6ZcJlW4Uu",
      usage_type: "licensed"
    }
  end

  def list(_attrs \\ %{}) do
    {:ok,
     %List{
       data: [
         retrieve()
       ],
       has_more: false,
       object: "list",
       total_count: nil,
       url: "/v1/plans"
     }}
  end
end
