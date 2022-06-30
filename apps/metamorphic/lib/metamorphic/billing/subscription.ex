defmodule Metamorphic.Billing.Subscription do
  use Ecto.Schema
  import Ecto.Changeset

  alias Metamorphic.Billing
  alias Metamorphic.Billing.Subscription
  alias Metamorphic.{Encrypted, Hashed}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "billing_subscriptions" do
    field :cancel_at, :naive_datetime
    field :current_period_end_at, :naive_datetime
    field :status, :string
    field :stripe_id, Encrypted.Binary
    field :stripe_id_hash, Hashed.HMAC
    field :trial_end_at, :naive_datetime

    belongs_to :plan, Billing.Plan, type: :binary_id, on_replace: :nilify
    belongs_to :customer, Billing.Customer, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [:stripe_id, :status, :current_period_end_at, :cancel_at, :trial_end_at])
    |> validate_required([:stripe_id, :status, :current_period_end_at])
    |> add_stripe_id_hash()
    |> validate_stripe_id_hash()
  end

  def checkout_changeset(%Subscription{} = subscription, attrs) do
    subscription
    |> cast(attrs, [:card_name])
    |> validate_required([:card_name])
    |> cast_assoc(:plan)
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
    |> unique_constraint(:stripe_id_hash, name: :billing_subscriptions_stripe_id_hash_index)
  end
end
