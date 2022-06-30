defmodule Metamorphic.Billing.Customer do
  use Ecto.Schema
  import Ecto.Changeset

  alias Metamorphic.Accounts
  alias Metamorphic.Billing
  alias Metamorphic.{Encrypted, Hashed}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "billing_customers" do
    field :default_source, :string
    field :stripe_id, Encrypted.Binary
    field :stripe_id_hash, Hashed.HMAC
    field :free_trial, :boolean

    belongs_to :person, Accounts.Person, type: :binary_id
    has_many :subscriptions, Billing.Subscription

    timestamps()
  end

  @doc false
  def changeset(customer, attrs) do
    customer
    |> cast(attrs, [:stripe_id, :default_source, :free_trial])
    |> validate_stripe_id()
    |> add_stripe_id_hash()
    |> validate_stripe_id_hash()
  end

  defp validate_stripe_id(changeset) do
    changeset
    |> validate_required([:stripe_id])
    |> unsafe_validate_unique([:stripe_id], Metamorphic.Repo)
    |> unique_constraint(:stripe_id, name: :billing_customers_stripe_id_index)
  end

  defp add_stripe_id_hash(changeset) do
    if Map.has_key?(changeset.changes, :stripe_id) do
      changeset |> put_change(:stripe_id_hash, get_field(changeset, :stripe_id))
    else
      changeset
    end
  end

  defp validate_stripe_id_hash(changeset) do
    changeset
    |> unsafe_validate_unique([:stripe_id_hash], Metamorphic.Repo)
    |> unique_constraint(:stripe_id_hash, name: :billing_customers_stripe_id_hash_index)
  end
end
