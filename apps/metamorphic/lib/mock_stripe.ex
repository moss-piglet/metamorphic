defmodule MockStripe do
  @moduledoc """
  Mock Stripe keeps the contexts that define and
  enable testing of the Stripe api and billing logic.

  Additionally, Mock Stripe generates the tokens
  necessary for testing in isolation of the Stripe service.
  """

  @doc """
  Generates Stripe-like custom tokens
  for testing.
  """
  def token do
    :crypto.strong_rand_bytes(25)
    |> Base.url_encode64()
    |> binary_part(0, 25)
    |> String.replace(~r/(_|-)/, "")
    |> String.slice(0..13)
  end
end
