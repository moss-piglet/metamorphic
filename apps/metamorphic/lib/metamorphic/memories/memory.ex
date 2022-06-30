defmodule Metamorphic.Memories.Memory do
  @moduledoc """
  Memory schema for `Memories` context.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Metamorphic.Accounts.Person
  alias Metamorphic.{Encrypted, Hashed}
  alias Metamorphic.Memories.SharedMemory

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "memories" do
    field :name, Encrypted.Binary, redact: true
    field :name_hash, Hashed.HMAC, redact: true
    field :temp_name, :string, virtual: true, redact: true
    field :file_size, Encrypted.Binary, redact: true
    field :file_type, Encrypted.Binary, redact: true
    field :memory_urls, Encrypted.StringList, redact: true
    field :description, Encrypted.Binary, redact: true
    field :person_key, Encrypted.Binary, redact: true
    field :favorite, :boolean, default: false
    field :hidden, :boolean, default: false

    belongs_to :person, Person, type: :binary_id
    has_many :shared_memories, SharedMemory

    timestamps()
  end

  @doc """
  A Memory changeset for a person's memories.
  """
  def changeset(memory, attrs) do
    memory
    |> cast(attrs, [:name, :temp_name, :person_id, :file_size, :file_type])
    |> validate_required([:person_id, :file_size, :file_type])
    |> validate_name()
  end

  @doc """
  A Memory changeset for saving the encrypted data.
  """
  def encrypted_changeset(memory, attrs) do
    memory
    |> cast(attrs, [:name, :temp_name, :person_id, :file_size, :file_type])
    |> validate_required([:person_id, :file_size, :file_type])
    |> validate_encrypted_name()
    |> maybe_delete_temp_name()
  end

  @doc """
  A Memory changeset for updating the favorite boolean.
  """
  def favorite_changeset(memory, attrs \\ %{}) do
    memory
    |> cast(attrs, [:favorite])
  end

  @doc """
  A Memory changeset for updating the hidden boolean.
  """
  def hidden_changeset(memory, attrs \\ %{}) do
    memory
    |> cast(attrs, [:hidden])
  end

  @doc """
  A Memory changeset for updating the description of a memory.
  """
  def description_changeset(memory, attrs) do
    memory
    |> cast(attrs, [:person_id, :description])
    |> validate_description()
  end

  defp validate_description(changeset) do
    changeset
    |> validate_length(:description, max: 250)
  end

  defp validate_name(changeset) do
    changeset
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 50)
    |> put_temp_name_change()
    |> add_name_hash()
    |> validate_name_hash()
  end

  defp validate_encrypted_name(changeset) do
    changeset
    |> validate_required([:name, :temp_name])
    |> validate_length(:temp_name, min: 2, max: 50)
    |> add_name_hash()
    |> validate_name_hash()
  end

  defp put_temp_name_change(changeset) do
    if Map.has_key?(changeset.changes, :name) do
      changeset
      |> put_change(:temp_name, get_field(changeset, :name))
    else
      changeset
    end
  end

  defp add_name_hash(changeset) do
    if Map.has_key?(changeset.changes, :temp_name) do
      changeset
      |> put_change(:name_hash, String.downcase(get_field(changeset, :temp_name)))
    else
      changeset
    end
  end

  defp validate_name_hash(changeset) do
    changeset
    |> unsafe_validate_unique([:name_hash, :person_id], Metamorphic.Repo)
    |> unique_constraint(:name_hash, name: :memories_person_id_name_hash_index)
  end

  defp maybe_delete_temp_name(changeset) do
    name_hash? = Map.has_key?(changeset.changes, :name_hash)
    temp_name = get_field(changeset, :temp_name)

    if name_hash? && temp_name && changeset.valid? do
      changeset
      |> delete_change(:temp_name)
    else
      changeset
    end
  end
end
