defmodule Metamorphic.Relationships.Relationship do
  @moduledoc """
  Relationship schema for the `Relationships` context.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Metamorphic.Constructor.SharedPortal
  alias Metamorphic.Encrypted
  alias Metamorphic.Memories.SharedMemory
  alias Metamorphic.Accounts
  alias Metamorphic.Relationships.RelationshipType

  @derive {Inspect, except: [:key_pair, :person_key, :relation_key, :relationship_key]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "relationships" do
    field :person_id, :binary_id, redact: true
    field :relation_id, :binary_id, redact: true
    field :relation_email, Encrypted.Binary, redact: true
    field :relation_name, Encrypted.Binary, redact: true
    field :relation_pseudonym, Encrypted.Binary, redact: true
    field :relation_key, Encrypted.Binary, redact: true
    field :person_name, Encrypted.Binary, redact: true
    field :person_email, Encrypted.Binary, redact: true
    field :person_pseudonym, Encrypted.Binary, redact: true
    field :person_key, Encrypted.Binary, redact: true
    field :relationship_key, Encrypted.Binary, redact: true
    field :key_pair, {:map, Encrypted.Binary}, redact: true
    field :confirmed_at, Encrypted.NaiveDateTime, redact: true
    field :can_download_memories?, Encrypted.Map, redact: true

    belongs_to :relationship_type, RelationshipType, type: :binary_id
    has_many :shared_memories, SharedMemory
    has_many :shared_portals, SharedPortal

    timestamps()
  end

  @doc false
  def changeset(relationship, attrs \\ %{}) do
    relationship
    |> cast(attrs, [
      :relationship_type_id,
      :person_id,
      :relation_id,
      :relationship_key,
      :key_pair,
      :relation_email,
      :relation_key,
      :person_name,
      :person_email,
      :person_pseudonym
    ])
    |> validate_required([:relationship_key, :key_pair])
    |> validate_relationship_type_id()
    |> validate_relation_email()
    |> validate_person_id()
    |> validate_relation_id()
  end

  @doc """
  Relationship changeset for updating relationships.

  Only allows the relationship_type to be updated. It
  requires the relationship_type_id to change otherwise
  an error is added.
  """
  def update_changeset(relationship, attrs \\ %{}) do
    relationship
    |> cast(attrs, [:relationship_type_id])
    |> validate_relationship_type_id()
    |> case do
      %{changes: %{relationship_type_id: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :relationship_type_id, "did not change")
    end
  end

  @doc """
  Relationship changeset for accepting a relationship
  request.
  """
  def accept_relationship_changeset(relationship, attrs \\ %{}) do
    relationship
    |> cast(attrs, [:relation_name, :relation_email, :relation_pseudonym, :person_key])
  end

  @doc """
  Relationship changeset for updating the controls for
  the current relationship. Currently supports only the
  `can_download_memories?` map.
  """
  def controls_changeset(relationship, attrs \\ %{}) do
    relationship
    |> cast(attrs, [:can_download_memories?])
  end

  defp validate_relationship_type_id(changeset) do
    changeset
    |> validate_required([:relationship_type_id])
    |> assoc_constraint(:relationship_type)
  end

  defp validate_relation_email(changeset) do
    changeset
    |> validate_required([:relation_email])
    |> validate_format(:relation_email, ~r/^([a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6})*$/,
      message: "must have the @ sign, no spaces, and/or proper format"
    )
    |> validate_length(:relation_email, max: 160)
  end

  defp validate_person_id(changeset) do
    changeset
    |> validate_required([:person_id])
  end

  defp validate_relation_id(changeset) do
    changeset
    |> maybe_add_relation_id()
  end

  defp maybe_add_relation_id(changeset) do
    relation_email = get_field(changeset, :relation_email)

    if is_nil(relation_email) do
      changeset
      |> put_change(:relation_id, nil)
    else
      relation = Accounts.find_person_by_relation_email(relation_email)

      if is_nil(relation) do
        changeset
        |> put_change(:relation_id, nil)
      else
        changeset
        |> put_change(:relation_id, relation.id)
        |> validate_unique_relationship()
      end
    end
  end

  defp validate_unique_relationship(changeset) do
    changeset
    |> unique_constraint([:person_id, :relation_id],
      name: :relationships_person_id_relation_id_index,
      message: "invalid email"
    )
    |> unique_constraint([:relation_id, :person_id],
      name: :relationships_relation_id_person_id_index,
      message: "invalid email"
    )
  end

  @doc """
  Confirms the relationship by setting `confirmed_at`.
  """
  def confirm_changeset(relationship) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(relationship, confirmed_at: now)
  end

  @doc """
  Returns true if the relationship is confirmed, false otherwise.
  """
  def is_confirmed?(relationship), do: relationship.confirmed_at != nil
end
