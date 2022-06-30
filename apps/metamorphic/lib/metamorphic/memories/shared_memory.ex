defmodule Metamorphic.Memories.SharedMemory do
  @moduledoc """
  SharedMemory schema for `Memories` context.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Metamorphic.Accounts.Person
  alias Metamorphic.Encrypted
  alias Metamorphic.Memories.Memory
  alias Metamorphic.Relationships.Relationship

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "shared_memories" do
    field :person_key, Encrypted.Binary, redact: true
    field :memory_urls, Encrypted.StringList, redact: true
    field :favorite, :boolean, default: false
    field :hidden, :boolean, default: false
    field :memory_origin_id, :binary_id, redact: true
    field :name, Encrypted.Binary, redact: true
    field :file_size, Encrypted.Binary, redact: true
    field :file_type, Encrypted.Binary, redact: true
    field :description, Encrypted.Binary, redact: true

    belongs_to :memory, Memory, type: :binary_id
    belongs_to :person, Person, type: :binary_id
    belongs_to :relationship, Relationship, type: :binary_id

    timestamps()
  end

  @doc """
  A SharedMemory changeset for sharing a person's memory.
  """
  def changeset(shared_memory, attrs \\ %{}) do
    shared_memory
    |> cast(attrs, [
      :memory_id,
      :memory_origin_id,
      :person_id,
      :relationship_id,
      :person_key,
      :memory_urls,
      :name,
      :file_size,
      :file_type,
      :description
    ])
    |> validate_required([
      :memory_id,
      :memory_origin_id,
      :person_id,
      :relationship_id,
      :person_key,
      :memory_urls,
      :name,
      :file_size,
      :file_type,
      :description
    ])
    |> unique_constraint([:memory_id, :person_id],
      name: :shared_memories_memory_id_person_id_index,
      message: "already shared"
    )
  end

  @doc """
  A SharedMemory changeset for updating the favorite boolean.
  """
  def favorite_changeset(shared_memory, attrs \\ %{}) do
    shared_memory
    |> cast(attrs, [:favorite])
  end

  @doc """
  A SharedMemory changeset for updating the hidden boolean.
  """
  def hidden_changeset(shared_memory, attrs \\ %{}) do
    shared_memory
    |> cast(attrs, [:hidden])
  end
end
