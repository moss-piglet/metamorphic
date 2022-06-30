defmodule Metamorphic.Announcements.Announcement do
  @moduledoc """
  `Announcement{}` schema for `Announcements` context.
  This is used by an `admin` to create announcements
  for people in the application.
  """
  use Ecto.Schema
  import Ecto.Changeset

  # alias Metamorphic.Accounts
  # alias Metamorphic.Accounts.Person
  alias Metamorphic.{Encrypted, Hashed}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "announcements" do
    field :title, Encrypted.Binary, redact: true
    field :title_hash, Hashed.HMAC, redact: true
    field :message, Encrypted.Binary, redact: true

    timestamps()
  end

  def changeset(announcement, attrs) do
    announcement
    |> cast(attrs, [:title, :message])
    |> validate_required([:title, :message])
    |> validate_title()
    |> validate_length(:message, min: 10, max: 500)
  end

  def admin_update_changeset(announcement, attrs) do
    announcement
    |> cast(attrs, [:title, :message])
    |> validate_required([:title, :message])
    |> validate_title()
    |> validate_length(:message, min: 10, max: 500)
  end

  defp validate_title(changeset) do
    changeset
    |> validate_required([:title])
    |> validate_length(:title, max: 50)
    |> add_title_hash()
    |> validate_title_hash()
  end

  defp add_title_hash(changeset) do
    if Map.has_key?(changeset.changes, :title) do
      changeset
      |> put_change(:title_hash, String.downcase(get_field(changeset, :title)))
    else
      changeset
    end
  end

  defp validate_title_hash(changeset) do
    changeset
    |> unsafe_validate_unique([:title_hash], Metamorphic.Repo)
    |> unique_constraint(:title_hash)
  end
end
