defmodule Metamorphic.Billing.CreateStripeCustomer do
  @moduledoc """
  GenServer to subscribe and handle the Stripe
  customer creation.
  """
  use GenServer
  import Ecto.Query, warn: false

  alias Metamorphic.Repo
  alias Metamorphic.Billing.Customer

  @stripe_service Application.compile_env(:metamorphic, :stripe_service)

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(state) do
    Metamorphic.Accounts.subscribe_on_person_created()
    {:ok, state}
  end

  def handle_info(%{person: person, temp_email: temp_email}, state) do
    case @stripe_service.Customer.create(%{email: temp_email}) do
      {:ok, %{id: stripe_id, default_source: default_source}} ->
        {:ok, billing_customer} =
          person
          |> Ecto.build_assoc(:billing_customer)
          |> Customer.changeset(%{stripe_id: stripe_id, default_source: default_source})
          |> Repo.insert()

        notify_subscribers(billing_customer)

        {:noreply, state}

      {:error, _stripe_error} ->
        # Try to talk to stripe 1 more time in case
        # of internet connection being temporarily dropped.
        {:ok, %{id: stripe_id, default_source: default_source}} =
          @stripe_service.Customer.create(%{email: temp_email})

        {:ok, billing_customer} =
          person
          |> Ecto.build_assoc(:billing_customer)
          |> Customer.changeset(%{stripe_id: stripe_id, default_source: default_source})
          |> Repo.insert()

        notify_subscribers(billing_customer)

        {:noreply, state}
    end
  end

  def handle_info(_, state), do: {:noreply, state}

  def subscribe do
    Phoenix.PubSub.subscribe(MetamorphicWeb.PubSub, "stripe_customer_created")
  end

  def notify_subscribers(customer) do
    Phoenix.PubSub.broadcast(
      MetamorphicWeb.PubSub,
      "stripe_customer_created",
      {:customer, customer}
    )
  end

  defmodule Stub do
    use GenServer
    def start_link(_), do: GenServer.start_link(__MODULE__, nil)
    def init(state), do: {:ok, state}
  end
end
