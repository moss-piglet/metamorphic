defmodule MetamorphicWeb.Plugs.StripeWebhooks do
  @moduledoc """
  A Plug module for Stripe.

  This will read the body of the request, read the
  `Stripe-Signature` header of the request, verify
  the authenticity of the Stripe Webhook Event, and
  attach the verified `%StripeEvent{}` object to
  the `conn`.

  Note, it only does this on requests to our webhooks
  route.

  ** Thank you to Conner Fritz.
  """
  @behaviour Plug

  import Plug.Conn

  def init(config), do: config

  def call(%{request_path: "/webhooks/stripe"} = conn, _) do
    signing_secret = Application.get_env(:stripity_stripe, :webhook_signing_key)
    [stripe_signature] = Plug.Conn.get_req_header(conn, "stripe-signature")

    with {:ok, body, _} <- Plug.Conn.read_body(conn),
         {:ok, stripe_event} <-
           Stripe.Webhook.construct_event(body, stripe_signature, signing_secret) do
      Plug.Conn.assign(conn, :stripe_event, stripe_event)
    else
      {:error, error} ->
        conn
        |> send_resp(:bad_request, error)
        |> halt()
    end
  end

  def call(conn, _), do: conn
end
