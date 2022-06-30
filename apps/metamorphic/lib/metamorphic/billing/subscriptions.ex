defmodule Metamorphic.Billing.Subscriptions do
  @moduledoc """
  The Billing Subscriptions context.
  """
  import Ecto.Query, warn: false

  alias Metamorphic.Repo
  alias Metamorphic.Billing
  alias Metamorphic.Billing.Subscription

  @doc """
  Returns the list of subscriptions.

  ## Examples

      iex> list_subscriptions()
      [%Subscription{}, ...]

  """
  def list_subscriptions do
    Repo.all(Subscription)
  end

  @doc """
  Gets a subscription for the current_customer.

  To be used for downloading subscription data and
  returning in a list. We can use this to download
  all of a current_customer's Stripe data on our end.
  """
  def safe_download_list_subscription_data(current_customer) when is_struct(current_customer) do
    preloads = [:customer, plan: [:product]]

    subscription =
      Repo.one(
        from s in Subscription,
          where: s.customer_id == ^current_customer.id,
          preload: ^preloads
      )

    [subscription]
  end

  @doc """
  Returns a list of subscriptions for the current_customer.
  """
  def safe_list_subscriptions(current_customer) when is_struct(current_customer) do
    preloads = [:customer, plan: [:product]]

    Repo.all(
      from s in Subscription,
        where: s.customer_id == ^current_customer.id,
        preload: ^preloads
    )
  end

  @doc """
  Gets a single subscription.

  Raises `Ecto.NoResultsError` if the Subscription does not exist.

  ## Examples

      iex> get_subscription!(123)
      %Subscription{}

      iex> get_subscription!(456)
      ** (Ecto.NoResultsError)

  """
  def get_subscription!(id), do: Repo.get!(Subscription, id)

  @doc """
  Preload plan for a subscription or list of subscriptions.

  ## Examples

      iex> with_plan(%Subscription{})
      %Subscription{plan: [%Plans{}]}
  """
  def with_plan(subscription_or_subscriptions) do
    subscription_or_subscriptions
    |> Repo.preload(:plan)
  end

  @doc """
  Gets a single subscription by Stripe Id.

  Raises `Ecto.NoResultsError` if the Subscription does not exist.

  ## Examples

      iex> get_subscription_by_stripe_id!(123)
      %Subscription{}

      iex> get_subscription_by_stripe_id!(456)
      ** (Ecto.NoResultsError)

  """
  def get_subscription_by_stripe_id!(stripe_id),
    do: Repo.get_by!(Subscription, stripe_id_hash: stripe_id)

  @doc """
  Gets a single subscription by Stripe Id.

  Returns `nil` if the Subscription does not exist.
  """
  def get_subscription_by_stripe_id(stripe_id),
    do: Repo.get_by(Subscription, stripe_id_hash: stripe_id)

  @doc """
  Gets a single active subscription for a person_id.

  Returns `nil` if an active Subscription does not exist.

  ## Examples

      iex> get_active_subscription_for_person(123)
      %Subscription{}

      iex> get_active_subscription_for_person(456)
      nil

  """
  def get_active_subscription_for_person(person_id) do
    from(s in Subscription,
      join: c in assoc(s, :customer),
      where: c.person_id == ^person_id,
      where: is_nil(s.cancel_at) or s.cancel_at > ^NaiveDateTime.utc_now(),
      where: s.current_period_end_at > ^NaiveDateTime.utc_now(),
      where: s.status == "active",
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  Gets a single trial subscription for a person_id.

  Returns `nil` if a trialing Subscription does not exist.

  ## Examples

      iex> get_trial_subscription_for_person(123)
      %Subscription{}

      iex> get_trial_subscription_for_person(456)
      nil

  """
  def get_trial_subscription_for_person(person_id) do
    from(s in Subscription,
      join: c in assoc(s, :customer),
      where: c.person_id == ^person_id,
      where: is_nil(s.cancel_at) or s.cancel_at > ^NaiveDateTime.utc_now(),
      where: s.current_period_end_at > ^NaiveDateTime.utc_now(),
      where: s.status == "trialing",
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  Gets a single active or trial subscription for a person_id.

  Returns `nil` if an active or trial Subscription does not exist.

  ## Examples

      iex> get_active_subscription_for_person(123)
      %Subscription{}

      iex> get_active_subscription_for_person(456)
      nil

  """
  def get_active_or_trial_subscription_for_person(person_id) do
    from(s in Subscription,
      where: is_nil(s.cancel_at) or s.cancel_at > ^NaiveDateTime.utc_now(),
      where: s.current_period_end_at > ^NaiveDateTime.utc_now(),
      where: s.status == "active",
      or_where: s.status == "trialing",
      join: c in assoc(s, :customer),
      where: c.person_id == ^person_id,
      limit: 1,
      preload: [:customer]
    )
    |> Repo.one()
  end

  def update_current_stripe_subscription(current_subscription) do
    unless is_nil(current_subscription) do
      case Stripe.Subscription.retrieve(current_subscription.stripe_id) do
        {:ok, current_subscription} ->
          case Billing.HandleSubscriptions.update_subscription(current_subscription) do
            {:ok, updated_subscription} ->
              updated_subscription

            _other ->
              nil
          end

        {:error, error} ->
          error
      end
    end
  end

  @doc """
  Creates a subscription.

  ## Examples

      iex> create_subscription(%{field: value})
      {:ok, %Subscription{}}

      iex> create_subscription(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_subscription(plan, customer, attrs \\ %{}) do
    plan
    |> Ecto.build_assoc(:subscriptions)
    |> Subscription.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:customer, customer)
    |> Repo.insert()
  end

  @doc """
  Updates a subscription.

  ## Examples

      iex> update_subscription(%{field: value})
      {:ok, %Subscription{}}

      iex> update_subscription(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_subscription(subscription, plan, customer, attrs \\ %{}) do
    unless is_nil(subscription) do
      attrs =
        attrs
        |> Map.put(:plan, [
          %{
            id: plan.id,
            amount: plan.amount,
            stripe_id: plan.stripe_id,
            stripe_plan_name: plan.stripe_plan_name
          }
        ])

      subscription
      |> Repo.preload([:plan, :customer])
      |> Subscription.changeset(attrs)
      |> Ecto.Changeset.put_change(:plan_id, plan.id)
      |> Ecto.Changeset.put_assoc(:plan, plan)
      |> Ecto.Changeset.put_assoc(:customer, customer)
      |> Repo.update()
    end
  end

  @doc """
  Cancels a subscription.

  ## Examples

      iex> cancel_subscription(subscription, %{field: new_value})
      {:ok, %Subscription{}}

      iex> cancel_subscription(subscription, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def cancel_subscription(%Subscription{} = subscription, _attrs) do
    subscription
    |> Repo.delete()
  end

  @doc """
  Deletes a subscription.

  ## Examples

      iex> delete_subscription(subscription)
      {:ok, %Subscription{}}

      iex> delete_subscription(subscription)
      {:error, %Ecto.Changeset{}}

  """
  def delete_subscription(%Subscription{} = subscription) do
    Repo.delete(subscription)
  end

  @doc """
  Safely delete the current subscription for the current_person.
  We need to ensure the current_person has their billing_customer
  preloaded.
  """
  def safe_delete_subscription(%Subscription{} = subscription, current_person) do
    if subscription.customer_id === current_person.billing_customer.id do
      Repo.delete(subscription)
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking subscription changes.

  ## Examples

      iex> change_subscription(subscription)
      %Ecto.Changeset{data: %Subscription{}}

  """
  def change_subscription(%Subscription{} = subscription, attrs \\ %{}) do
    Subscription.changeset(subscription, attrs)
  end

  ## Admin getters and counters

  @doc false
  def admin_safe_count_all_subscriptions(current_person) do
    unless is_nil(current_person) || current_person.privileges != :admin do
      Repo.aggregate(Subscription, :count)
    end
  end

  @doc false
  def admin_safe_count_all_trial_subscriptions(current_person) do
    unless is_nil(current_person) || current_person.privileges != :admin do
      query = from s in Subscription, where: s.status == ^"trialing"
      Repo.aggregate(query, :count)
    end
  end

  @doc false
  def admin_safe_count_all_active_subscriptions(current_person) do
    unless is_nil(current_person) || current_person.privileges != :admin do
      query = from s in Subscription, where: s.status == ^"active"
      Repo.aggregate(query, :count)
    end
  end

  @doc false
  def admin_safe_count_all_canceled_subscriptions(current_person) do
    unless is_nil(current_person) || current_person.privileges != :admin do
      query = from s in Subscription, where: s.status == ^"canceled"
      Repo.aggregate(query, :count)
    end
  end
end
