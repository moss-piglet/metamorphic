defmodule MockStripe.PaymentMethod do
  @moduledoc """
  Module for setting up fake data to
  mimic Stripe data for mocking tests.

  This mimics the Stripe PaymentMethod struct.
  """
  alias MockStripe.PaymentMethod

  defstruct [
    :card,
    :customer,
    :id,
    :object,
    :type
  ]

  def attach(%{customer: customer, payment_method: id}) do
    {:ok,
     retrieve()
     |> Map.merge(%{customer: customer, id: id})}
  end

  def retrieve() do
    stripe_id = "pm_#{MockStripe.token()}"
    retrieve(stripe_id)
  end

  def retrieve("pm_" <> _ = stripe_id) do
    %PaymentMethod{
      card: %{
        brand: "visa",
        checks: %{
          address_postal_code_check: "pass",
          cvc_check: "pass"
        },
        country: "US",
        exp_month: 4,
        exp_year: 2024,
        fingerprint: MockStripe.token(),
        funding: "credit",
        last4: "4242",
        networks: %{available: ["visa"], preferred: nil},
        three_d_secure_usage: %{supported: true}
      },
      customer: "cus_#{MockStripe.token()}",
      id: stripe_id,
      object: "payment_method",
      type: "card"
    }
  end
end
