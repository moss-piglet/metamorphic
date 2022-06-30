defmodule Metamorphic.Billing.Product do
  use Ecto.Schema
  import Ecto.Changeset

  alias Metamorphic.Billing

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "billing_products" do
    field :stripe_id, :string
    field :stripe_product_name, :string
    field :description, :string

    has_many :plans, Billing.Plan, foreign_key: :billing_product_id

    timestamps()
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:stripe_id, :stripe_product_name, :description])
    |> validate_stripe_id()
    |> validate_stripe_product_name()
  end

  defp validate_stripe_id(changeset) do
    changeset
    |> validate_required([:stripe_id])
    |> unsafe_validate_unique([:stripe_id], Metamorphic.Repo)
    |> unique_constraint(:stripe_id, name: :billing_products_stripe_id_index)
  end

  defp validate_stripe_product_name(changeset) do
    changeset
    |> validate_required([:stripe_product_name])
  end
end
