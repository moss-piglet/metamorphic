defmodule Metamorphic.Workers.StripeWebhooksInvoicesWorker do
  @moduledoc """
  Oban worker for getting `current_person.billing_customer`'s
  invoices from Stripe.
  """
  use Oban.Worker, queue: :events, unique: [period: 10]

  @stripe_service Application.compile_env(:metamorphic, :stripe_service)

  def perform(%Oban.Job{
        args: %{
          "customer" => customer_stripe_id,
          "limit" => limit
        }
      }) do
    {:ok, %Stripe.List{data: invoices}} =
      @stripe_service.Invoice.list(%{customer: customer_stripe_id, limit: limit})

    invoices
  end
end
