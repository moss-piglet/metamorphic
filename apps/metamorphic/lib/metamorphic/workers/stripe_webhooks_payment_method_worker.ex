defmodule Metamorphic.Workers.StripeWebhooksPaymentMethodWorker do
  @moduledoc """
  Oban worker for attaching payment methods to Stripe.
  """
  use Oban.Worker, queue: :events, unique: [period: 10]

  @stripe_service Application.compile_env(:metamorphic, :stripe_service)

  def perform(%Oban.Job{
        args: %{
          "customer_stripe_id" => customer_stripe_id,
          "payment_method_id" => payment_method_id
        }
      }) do
    {:ok, payment_method} =
      @stripe_service.PaymentMethod.attach(%{
        customer: customer_stripe_id,
        payment_method: payment_method_id
      })

    @stripe_service.Customer.update(customer_stripe_id, %{
      invoice_settings: %{default_payment_method: payment_method.id}
    })

    :ok
  end
end
