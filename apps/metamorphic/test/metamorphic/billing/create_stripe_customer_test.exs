defmodule Metamorphic.Billing.CreateStripeCustomerTest do
  use Metamorphic.DataCase
  import Metamorphic.AccountsFixtures

  alias Metamorphic.{Accounts, Billing}
  alias Metamorphic.Billing.CreateStripeCustomer

  describe "creating a stripe customer and billing customer" do
    test "creates a billing customer after broadcasting it" do
      {person, temp_email, _, _} = person_fixture()
      %{id: id} = person
      start_supervised(CreateStripeCustomer, [])
      CreateStripeCustomer.subscribe()

      Accounts.notify_subscribers({:ok, person}, temp_email)

      assert_receive({:customer, _})
      assert [%{person_id: ^id, stripe_id: "" <> _}] = Billing.Customers.list_customers()
    end
  end
end
