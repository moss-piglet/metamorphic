defmodule Metamorphic.Relationships.SharedAvatar do
  @moduledoc """
  SharedMemory schema for `Relationships` context.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Metamorphic.Accounts.Person
  alias Metamorphic.Encrypted
  alias Metamorphic.Relationships.Relationship

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "shared_avatars" do
    field :shared_key, Encrypted.Binary, redact: true
    field :avatar_urls, Encrypted.StringList, redact: true
    field :is_sharing_avatar, :boolean, default: false

    belongs_to :person, Person, type: :binary_id
    belongs_to :relationship, Relationship, type: :binary_id

    timestamps()
  end

  @doc """
  A SharedAvatar changeset for creating a relationship's SharedAvatars.
  """
  def changeset(shared_avatar, attrs \\ %{}) do
    shared_avatar
    |> cast(attrs, [:person_id, :relationship_id, :shared_key, :avatar_urls])
    |> validate_required([:person_id, :relationship_id])
    |> unique_constraint([:person_id, :relationship_id],
      name: :shared_avatars_person_id_relationship_id_index,
      message: "already shared"
    )
  end

  @doc """
  A changeset for sharing a person's avatar.
  """
  def share_avatar_changeset(shared_avatar, attrs \\ %{}) do
    shared_avatar
    |> cast(attrs, [:person_id, :relationship_id, :avatar_urls, :shared_key, :is_sharing_avatar])
  end
end
