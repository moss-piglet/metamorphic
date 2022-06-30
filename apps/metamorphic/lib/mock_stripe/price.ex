defmodule MockStripe.Price do
  @moduledoc """
  Module for setting up fake data to
  mimic Stripe data for mocking tests.

  This mimics the Stripe Price struct.
  """
  defstruct [
    :active,
    :billing_scheme,
    :currency,
    :id,
    :nickname,
    :object,
    :product,
    :type,
    :unit_amount
  ]

  alias MockStripe.List
  alias MockStripe.Price

  def retrieve() do
    stripe_id = "price_#{MockStripe.token()}"
    retrieve(stripe_id)
  end

  def retrieve("price_" <> _ = stripe_id) do
    %Price{
      active: true,
      billing_scheme: "per_unit",
      currency: "usd",
      id: stripe_id,
      nickname: "One year membership",
      object: "price",
      product: "prod_I2TE8siyANz84p",
      type: "recurring",
      unit_amount: 140_000
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
       url: "/v1/prices"
     }}
  end
end
