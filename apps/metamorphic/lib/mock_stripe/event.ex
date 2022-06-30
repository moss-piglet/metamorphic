defmodule MockStripe.Event do
  @moduledoc """
  Module for setting up fake data to
  mimic Stripe data for mocking tests.

  This mimics the Stripe Event struct.
  """
  defstruct [
    :id,
    :object,
    :request,
    :type
  ]

  alias MockStripe.Event

  def generate(attrs \\ %{}) do
    %Event{
      id: "evt_#{MockStripe.token()}",
      object: "event",
      request: %{
        id: "req_#{MockStripe.token()}",
        idempotency_key: MockStripe.token()
      },
      type: "payment_intent.created"
    }
    |> Map.merge(attrs)
  end
end
