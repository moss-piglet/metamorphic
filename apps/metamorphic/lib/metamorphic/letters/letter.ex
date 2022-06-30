defmodule Metamorphic.Letters.Letter do
  @moduledoc """
  Letter schema for `Letters` context.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Metamorphic.Accounts.Person
  alias Metamorphic.Encrypted
  alias Metamorphic.Relationships.Relationship
  # alias Metamorphic.Memories.SharedMemory

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "letters" do
    field :body, Encrypted.Binary, redact: true
    field :person_key, Encrypted.Binary, redact: true
    field :letter_origin_id, :binary_id, redact: true
    field :recipients, {:array, :string}, virtual: true

    belongs_to :person, Person, type: :binary_id
    belongs_to :relationship, Relationship, type: :binary_id

    timestamps()
  end

  @doc """
  A Letter changeset for a person's letters.
  """
  def changeset(letter, attrs) do
    letter
    |> cast(attrs, [
      :person_id,
      :body,
      :recipients,
      :relationship_id,
      :person_key,
      :letter_origin_id
    ])
    |> validate_required([:person_id, :recipients, :body, :letter_origin_id])
    |> validate_recipients()
  end

  defp validate_recipients(changeset) do
    changeset
    |> validate_length(:recipients, max: 250)
  end
end
