defmodule Metamorphic.Workers.StripeDeleteCustomerWorker do
  @moduledoc """
  Oban worker for deleting person avatars.
  """
  use Oban.Worker, queue: :events

  def perform(%Oban.Job{args: %{"stripe_id" => stripe_id}}) do
    Stripe.Customer.delete(stripe_id)

    :ok
  end
end
