defmodule MockStripe.Webhook do
  @moduledoc """
  Module for setting up fake data to
  mimic Stripe data for mocking tests.

  This mimics the Stripe Webhook to generate
  events.
  """
  alias MockStripe.Event

  def construct_event(_raw_body, "wrong_signature" = _stripe_signature, _webhook_signing_key) do
    send(self(), {:ok, "invalid_webhook"})

    {:error, "Signature has expired"}
  end

  def construct_event(_raw_body, _stripe_signature, _webhook_signing_key) do
    send(self(), {:ok, "valid_webhook"})

    {:ok, Event.generate()}
  end
end
