defmodule Metamorphic.Billing.SynchronizeProductsTest do
  use Metamorphic.DataCase

  alias Metamorphic.Billing
  alias Metamorphic.Billing.SynchronizeProducts

  describe "run" do
    test "run/0 syncs products from Stripe and creates them in billing_products" do
      assert Billing.Products.list_products() == []

      SynchronizeProducts.run()
      assert [%Billing.Product{}] = Billing.Products.list_products()
    end

    test "run/0 deletes products that exist in local database but not in Stripe" do
      # Deletes products out-of-sync with Stripe
      {:ok, product} =
        Billing.create_product(%{
          stripe_product_name: "Does not exist",
          stripe_id: "prod_abc123def456"
        })

      assert Billing.Products.list_products() == [product]

      SynchronizeProducts.run()
      assert_raise(Ecto.NoResultsError, fn -> Billing.Products.get_product!(product.id) end)
    end
  end
end
