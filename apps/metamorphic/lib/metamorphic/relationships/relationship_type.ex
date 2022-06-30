defmodule Metamorphic.Relationships.RelationshipType do
  @moduledoc """
  `RelationshipType` schema for the `Relationships` context.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Metamorphic.{Encrypted, Hashed}
  alias Metamorphic.Relationships.Relationship

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "relationship_types" do
    field :name, Encrypted.Binary
    field :name_hash, Hashed.HMAC

    has_many :relationships, Relationship

    timestamps()
  end

  @doc false
  def changeset(relationship_type, attrs) do
    relationship_type
    |> cast(attrs, [:name])
    |> validate_name()
  end

  defp validate_name(changeset) do
    changeset
    |> validate_required([:name])
    |> add_name_hash()
  end

  defp add_name_hash(changeset) do
    if Map.has_key?(changeset.changes, :name) do
      changeset |> put_change(:name_hash, String.downcase(get_field(changeset, :name)))
    else
      changeset
    end
  end
end
