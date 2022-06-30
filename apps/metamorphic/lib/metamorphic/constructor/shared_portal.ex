defmodule Metamorphic.Constructor.SharedPortal do
  @moduledoc """
  SharedPortal schema for `Constructor` context.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Metamorphic.Accounts.Person
  alias Metamorphic.{Encrypted, Hashed}
  alias Metamorphic.Constructor.Portal
  alias Metamorphic.Relationships.Relationship

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "shared_portals" do
    field :person_key, Encrypted.Binary, redact: true
    field :name, Encrypted.Binary
    field :slug, Encrypted.Binary
    field :temp_slug, :string, virtual: true
    field :temp_portal_pass, :string, virtual: true
    field :slug_hash, Hashed.HMAC
    field :portal_pass, Encrypted.Binary, redact: true
    field :hashed_portal_pass, Encrypted.Binary, redact: true
    field :portal_origin_id, :binary_id, redact: true

    belongs_to :portal, Portal, type: :binary_id
    belongs_to :person, Person, type: :binary_id
    belongs_to :relationship, Relationship, type: :binary_id

    timestamps()
  end

  @doc """
  A SharedPortal changeset for sharing a person's portal.
  """
  def changeset(shared_portal, attrs \\ %{}) do
    shared_portal
    |> cast(attrs, [
      :portal_id,
      :person_id,
      :relationship_id,
      :person_key,
      :name,
      :slug,
      :temp_slug,
      :portal_pass,
      :hashed_portal_pass,
      :portal_origin_id
    ])
    |> validate_required([
      :portal_id,
      :person_id,
      :relationship_id,
      :person_key,
      :name,
      :slug,
      :temp_slug,
      :portal_pass,
      :hashed_portal_pass,
      :portal_origin_id
    ])
    |> validate_temp_slug()
    |> unique_constraint([:portal_id, :person_id],
      name: :shared_portals_portal_id_person_id_index,
      message: "already shared"
    )
  end

  defp validate_temp_slug(changeset) do
    changeset
    |> validate_required([:temp_slug])
    |> add_temp_slug_hash()
  end

  defp add_temp_slug_hash(changeset) do
    temp_slug = get_change(changeset, :temp_slug)

    if temp_slug do
      changeset
      |> put_change(:slug_hash, get_field(changeset, :temp_slug))
      |> delete_change(:temp_slug)
    else
      add_error(changeset, :slug, "invalid slug")
    end
  end
end
