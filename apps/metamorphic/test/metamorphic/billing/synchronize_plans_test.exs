defmodule Metamorphic.Billing.SynchronizePlansTest do
  use Metamorphic.DataCase

  alias Metamorphic.Billing
  alias Metamorphic.Billing.SynchronizePlans

  def create_product() do
    {:ok, product} =
      Billing.Products.create_product(%{
        stripe_product_name: "Member Plan",
        stripe_id: "prod_JZJra6ZcJlW4Uu"
      })

    product
  end

  describe "run" do
    test "run/0 syncs plans from Stripe and creates them in billing_plans" do
      %Billing.Product{} = create_product()
      assert Billing.Plans.list_plans() == []

      SynchronizePlans.run()
      assert [%Billing.Plan{}] = Billing.Plans.list_plans()
    end

    test "run/0 deletes plans that exist in local database but not in Stripe" do
      %Billing.Product{} = product = create_product()
      # Deletes plans out-of-sync with Stripe
      {:ok, plan} =
        Billing.Plans.create_plan(product, %{
          stripe_plan_name: "Does not exist",
          stripe_id: "price_abc123def456",
          amount: "333"
        })

      assert Billing.Plans.list_plans() == [plan]

      SynchronizePlans.run()
      assert_raise(Ecto.NoResultsError, fn -> Billing.Plans.get_plan!(plan.id) end)
    end
  end
end
