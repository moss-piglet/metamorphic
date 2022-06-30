defmodule Metamorphic.Constructor.Portal do
  @moduledoc """
  Portal schema for `Constructor` context.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Metamorphic.{Encrypted, Hashed}

  @derive {Inspect, except: [:portal_pass, :hashed_portal_pass, :person_key]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "portals" do
    field :name, Encrypted.Binary
    field :slug, Encrypted.Binary
    field :slug_hash, Hashed.HMAC
    field :temp_slug, :string, virtual: true
    field :portal_pass, Encrypted.Binary
    field :hashed_portal_pass, Encrypted.Binary, redact: true
    field :person_key, Encrypted.Binary

    belongs_to :person, Metamorphic.Accounts.Person, type: :binary_id
    has_many :shared_portals, Metamorphic.Constructor.SharedPortal

    timestamps()
  end

  @doc """
  Portal changeset for validating portals before saving.
  """
  def changeset(portal, attrs) do
    portal
    |> cast(attrs, [:name, :slug, :person_id])
    |> validate_name()
    |> validate_slug()
    |> validate_person_id()
  end

  @doc """
  Encrypted changeset for saving the portal with encrypted atttributes.
  """
  def encrypted_changeset(portal, attrs) do
    portal
    |> cast(attrs, [
      :name,
      :slug,
      :temp_slug,
      :portal_pass,
      :hashed_portal_pass,
      :person_key,
      :person_id
    ])
    |> validate_required([
      :name,
      :slug,
      :temp_slug,
      :portal_pass,
      :hashed_portal_pass,
      :person_key,
      :person_id
    ])
    |> validate_temp_slug()
  end

  defp validate_name(changeset) do
    changeset
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 160)
  end

  defp validate_slug(changeset) do
    changeset
    |> validate_required([:slug])
    |> validate_length(:slug, min: 2, max: 160)
    |> validate_format(:slug, ~r/^[a-z0-9\s]+(?:-[a-z0-9]+)*$/i,
      message: "must be word or url characters only"
    )
    |> format_slug()
    |> add_slug_hash()
    |> validate_slug_hash()
  end

  defp validate_temp_slug(changeset) do
    changeset
    |> validate_required([:temp_slug])
    |> validate_length(:temp_slug, min: 2, max: 160)
    |> validate_format(:temp_slug, ~r/^[a-z0-9\s]+(?:-[a-z0-9]+)*$/i,
      message: "must be word or url characters only"
    )
    |> add_temp_slug_hash()
    |> validate_slug_hash()
  end

  defp format_slug(%Ecto.Changeset{changes: %{slug: _}} = changeset) do
    changeset
    |> update_change(:slug, fn slug ->
      slug
      |> String.downcase()
      |> String.replace(" ", "-")
    end)
  end

  defp format_slug(changeset), do: changeset

  defp add_slug_hash(changeset) do
    if Map.has_key?(changeset.changes, :slug) do
      changeset |> put_change(:slug_hash, get_field(changeset, :slug))
    else
      changeset
    end
  end

  defp validate_slug_hash(changeset) do
    changeset
    |> unsafe_validate_unique([:slug_hash], Metamorphic.Repo)
    |> unique_constraint(:slug_hash)
  end

  defp add_temp_slug_hash(changeset) do
    temp_slug = get_change(changeset, :temp_slug)

    if temp_slug do
      changeset
      |> put_change(:slug_hash, get_field(changeset, :temp_slug))
      |> delete_change(:temp_slug)
    else
      add_error(changeset, :slug_hash, "invalid slug")
    end
  end

  defp validate_person_id(changeset) do
    changeset
    |> validate_required([:person_id])
  end
end
