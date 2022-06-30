defmodule MockStripe.Product do
  @moduledoc """
  Module for setting up fake data to
  mimic Stripe data for mocking tests.

  This mimics the Stripe Product struct.
  """
  defstruct [
    :created,
    :id,
    :name,
    :object,
    :updated
  ]

  alias MockStripe.List
  alias MockStripe.Product

  def retrieve() do
    stripe_id = "prod_#{MockStripe.token()}"
    retrieve(stripe_id)
  end

  def retrieve("prod_" <> _ = stripe_id) do
    %Product{
      created: 1_600_353_622,
      id: stripe_id,
      name: "Member Plan",
      object: "product",
      updated: 1_600_798_919
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
       url: "/v1/products"
     }}
  end
end
