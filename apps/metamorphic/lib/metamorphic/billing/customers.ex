defmodule Metamorphic.Billing.Customers do
  @moduledoc """
  The Billing Customers context.
  """
  import Ecto.Query, warn: false

  alias Metamorphic.Repo
  alias Metamorphic.Billing.Customer

  @doc """
  Returns the list of customers.

  ## Examples

      iex> list_customers()
      [%Customer{}, ...]

  """
  def list_customers do
    Repo.all(Customer)
  end

  @doc """
  Gets a single customer.

  Raises `Ecto.NoResultsError` if the Customer does not exist.

  ## Examples

      iex> get_customer!(123)
      %Customer{}

      iex> get_customer!(456)
      ** (Ecto.NoResultsError)

  """
  def get_customer!(id), do: Repo.get!(Customer, id)

  @doc """
  Gets a single customer for the current_person.

  Raises `nil` if the Customer does not exist.

  ## Examples

      iex> safe_get_customer(current_person)
      %Customer{}

      iex> safe_get_customer(456)
      nil

  """
  def safe_get_customer(current_person) do
    Repo.one(
      from c in Customer,
        where: c.person_id == ^current_person.id
    )
  end

  @doc """
  Preload subscriptions for a customer or list of customers.

  ## Examples

      iex> with_subscriptions(%Customer{})
      %Customer{subscriptions: [%Subscriptions{}]}
  """
  def with_subscriptions(customer_or_customers) do
    customer_or_customers
    |> Repo.preload(:subscriptions)
  end

  @doc """
  Gets a single customer by Stripe Id.

  Raises `Ecto.NoResultsError` if the Customer does not exist.

  ## Examples

      iex> get_customer_by_stripe_id!(123)
      %Customer{}

      iex> get_customer_by_stripe_id!(456)
      ** (Ecto.NoResultsError)
  """
  def get_customer_by_stripe_id!(stripe_id), do: Repo.get_by!(Customer, stripe_id_hash: stripe_id)

  @doc """
  Gets a single customer by Stripe Id.

  Returns `nil` if the Customer does not exist.

  ## Examples

      iex> get_customer_by_stripe_id(123)
      %Customer{}

      iex> get_customer_by_stripe_id(456)
      nil
  """
  def get_customer_by_stripe_id(stripe_id), do: Repo.get_by(Customer, stripe_id_hash: stripe_id)

  @doc """
  Gets a single customer for a person_id.

  Returns nil if the Customer does not exist.

  ## Examples

    iex> get_billing_customer_for_person(%Person{id: 123})
    %Customer{}

    iex> get_billing_customer_for_person(%Person{id: 456})
    nil
  """
  def get_billing_customer_for_person(person) do
    Repo.get_by(Customer, person_id: person.id)
  end

  @doc """
  Creates a customer.

  ## Examples

      iex> create_customer(person, %{field: value})
      {:ok, %Customer{}}

      iex> create_customer(person, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_customer(person, attrs \\ %{}) do
    person
    |> Ecto.build_assoc(:billing_customer)
    |> Customer.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a customer.

  ## Examples

      iex> update_customer(customer, %{field: new_value})
      {:ok, %Customer{}}

      iex> update_customer(customer, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_customer(%Customer{} = customer, attrs) do
    customer
    |> Customer.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a customer.

  ## Examples

      iex> delete_customer(customer)
      {:ok, %Customer{}}

      iex> delete_customer(customer)
      {:error, %Ecto.Changeset{}}

  """
  def delete_customer(%Customer{} = customer) do
    Repo.delete(customer)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking customer changes.

  ## Examples

      iex> change_customer(customer)
      %Ecto.Changeset{data: %Customer{}}

  """
  def change_customer(%Customer{} = customer, attrs \\ %{}) do
    Customer.changeset(customer, attrs)
  end
end
