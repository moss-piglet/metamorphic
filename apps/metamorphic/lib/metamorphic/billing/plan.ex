defmodule Metamorphic.Billing.Plan do
  use Ecto.Schema
  import Ecto.Changeset

  alias Metamorphic.Billing

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "billing_plans" do
    field :amount, :integer
    field :stripe_id, :string
    field :stripe_plan_name, :string
    field :interval, :string

    belongs_to :product, Billing.Product, foreign_key: :billing_product_id, type: :binary_id
    has_many :subscriptions, Billing.Subscription

    timestamps()
  end

  @doc false
  def changeset(plan, attrs) do
    plan
    |> cast(attrs, [:stripe_id, :stripe_plan_name, :amount, :interval])
    |> validate_stripe_id()
    |> validate_stripe_plan_name()
    |> validate_amount()
    |> validate_interval()
  end

  @doc false
  def update_changeset(plan, attrs) do
    plan
    |> cast(attrs, [:id, :stripe_id, :stripe_plan_name, :amount, :interval])
    |> validate_required([:stripe_id])
    |> validate_stripe_plan_name()
    |> validate_amount()
    |> validate_interval()
  end

  defp validate_stripe_id(changeset) do
    changeset
    |> validate_required([:stripe_id])
    |> unsafe_validate_unique([:stripe_id], Metamorphic.Repo)
    |> unique_constraint(:stripe_id, name: :billing_plans_stripe_id_index)
  end

  defp validate_stripe_plan_name(changeset) do
    changeset
    |> validate_required([:stripe_plan_name])
  end

  defp validate_amount(changeset) do
    changeset
    |> validate_required([:amount])
  end

  defp validate_interval(changeset) do
    changeset
    |> validate_required([:interval])
  end
end
