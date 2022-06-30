defmodule MockStripe.Customer do
  @moduledoc """
  Module for setting up fake data to
  mimic Stripe data for mocking tests.

  This mimics the Stripe Customer struct.
  """
  defstruct [
    :created,
    :default_source,
    :email,
    :id,
    :name,
    :object
  ]

  alias MockStripe.List
  alias MockStripe.Customer

  def create(attrs \\ %{}) do
    {:ok,
     retrieve()
     |> Map.merge(attrs)}
  end

  def retrieve() do
    stripe_id = "cus_#{MockStripe.token()}"
    retrieve(stripe_id)
  end

  def retrieve("cus_" <> _ = stripe_id) do
    %Customer{
      created: 1_600_892_385,
      email: "dev@metamorphic.app",
      id: stripe_id,
      name: "Dev Metamorphic",
      object: "customer"
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
       url: "/v1/customers"
     }}
  end

  def update(customer_stripe_id, attrs) do
    {:ok,
     retrieve()
     |> Map.merge(%{id: customer_stripe_id})
     |> Map.merge(attrs)}
  end
end
