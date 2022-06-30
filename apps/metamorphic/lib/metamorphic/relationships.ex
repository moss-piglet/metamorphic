defmodule Metamorphic.Relationships do
  @moduledoc """
  The Relationships context.
  """
  import Ecto.Query, warn: false

  alias Metamorphic.Repo
  alias Metamorphic.Accounts
  alias Metamorphic.Accounts.Person
  alias Metamorphic.Encrypted
  alias Metamorphic.Relationships.{Relationship, RelationshipType, SharedAvatar}
  alias MetamorphicWeb.RealTime

  ## Relationship registration

  @doc """
  Adds a relationship to a person.
  """
  def register_relationship(attrs) do
    %Relationship{}
    |> Relationship.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Accepts a relationship for a person and
  adds the properly re-encrypted relation
  fields.
  """
  def register_accepting_relationship(
        %Relationship{} = relationship,
        requesting_person,
        current_person,
        current_person_key,
        attrs \\ %{}
      ) do
    attrs =
      attrs
      |> Map.put("relation_name", "")
      |> Map.put("relation_pseudonym", "")
      |> Map.put("person_key", "")
      |> build_accepting_relationship_fields(
        requesting_person,
        current_person,
        current_person_key
      )

    relationship
    |> Relationship.accept_relationship_changeset(attrs)
    |> Repo.update()
  end

  defp build_accepting_relationship_fields(
         relationship_attrs,
         requesting_person,
         current_person,
         current_person_key
       ) do
    relationship_attrs =
      relationship_attrs
      |> put_relationship_encrypted_relation_fields(
        requesting_person,
        current_person,
        current_person_key
      )

    relationship_attrs
  end

  defp put_relationship_encrypted_relation_fields(
         relationship_attrs,
         requesting_person,
         current_person,
         current_person_key
       ) do
    person_key = Encrypted.Utils.generate_key()

    relation_name =
      Encrypted.Relationships.Utils.decrypt_current_person_accepting_relationship(
        current_person.name,
        current_person.person_key,
        current_person,
        current_person_key
      )

    relation_email =
      Encrypted.Relationships.Utils.decrypt_current_person_accepting_relationship(
        current_person.email,
        current_person.person_key,
        current_person,
        current_person_key
      )

    relation_pseudonym =
      Encrypted.Relationships.Utils.decrypt_current_person_accepting_relationship(
        current_person.pseudonym,
        current_person.person_key,
        current_person,
        current_person_key
      )

    encrypted_relation_name = Encrypted.Utils.encrypt(%{key: person_key, payload: relation_name})

    encrypted_relation_email =
      Encrypted.Utils.encrypt(%{key: person_key, payload: relation_email})

    encrypted_relation_pseudonym =
      Encrypted.Utils.encrypt(%{key: person_key, payload: relation_pseudonym})

    encrypted_person_key =
      Encrypted.Utils.encrypt_message_for_user_with_pk(person_key, %{
        public: requesting_person.key_pair["public"]
      })

    relationship_attrs
    |> Map.put("relation_name", encrypted_relation_name)
    |> Map.put("relation_email", encrypted_relation_email)
    |> Map.put("relation_pseudonym", encrypted_relation_pseudonym)
    |> Map.put("person_key", encrypted_person_key)
  end

  @doc """
  Shares an avatar.
  """
  def share_avatar(%SharedAvatar{} = shared_avatar, attrs \\ %{}) do
    if shared_avatar.id do
      shared_avatar
      |> SharedAvatar.share_avatar_changeset(attrs)
      |> Repo.update()

      # |> RealTime.Person.Memory.broadcast_share_memory()
    else
      shared_avatar
      |> SharedAvatar.share_avatar_changeset(attrs)
      |> Repo.insert()

      # |> RealTime.Person.Memory.broadcast_share_memory()
    end
  end

  @doc """
  Updates all SharedAvatars for a current_person's relationships.
  Refer to Accounts.update_avatar().
  """
  def update_all_shared_avatars(avatar_urls, relationships) do
    Enum.each(
      relationships,
      fn person ->
        from(sa in SharedAvatar,
          where: sa.person_id == ^person.id,
          update: [set: [avatar_urls: ^avatar_urls]]
        )
        |> Repo.update_all([])
      end
    )
  end

  @doc """
  Creates shared avatars for the
  person side of a relationship.
  """
  def create_shared_person_avatars(%Relationship{} = relationship, _attrs \\ []) do
    shared_person_avatar_attrs = build_shared_person_avatar_attrs(relationship, %{})
    attrs = shared_person_avatar_attrs

    %SharedAvatar{}
    |> SharedAvatar.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates shared avatars for the
  relation side of a relationship.
  """
  def create_shared_relation_avatars(%Relationship{} = relationship, _attrs \\ []) do
    shared_relation_avatar_attrs = build_shared_relation_avatar_attrs(relationship, %{})
    attrs = shared_relation_avatar_attrs

    %SharedAvatar{}
    |> SharedAvatar.changeset(attrs)
    |> Repo.insert()
  end

  defp build_shared_person_avatar_attrs(relationship, %{} = shared_avatar_params) do
    shared_avatar_params =
      shared_avatar_params
      |> Map.put("person_id", relationship.person_id)
      |> Map.put("relationship_id", relationship.id)
      |> Map.put("shared_key", nil)
      |> Map.put("avatar_urls", nil)

    shared_avatar_params
  end

  defp build_shared_relation_avatar_attrs(relationship, %{} = shared_avatar_params) do
    shared_avatar_params =
      shared_avatar_params
      |> Map.put("person_id", relationship.relation_id)
      |> Map.put("relationship_id", relationship.id)
      |> Map.put("shared_key", nil)
      |> Map.put("avatar_urls", nil)

    shared_avatar_params
  end

  ## Confirmation of relationships

  @doc """
  Delivers the confirmation token to the given person of the relationship.
  Stays within the app to protect people's privacy.
  """
  def deliver_relationship_app_confirmation(
        %Person{} = sent_to_person,
        %Relationship{} = relationship,
        %Person{} = requesting_person
      )
      when not is_nil(sent_to_person) and not is_nil(requesting_person) do
    if relationship.confirmed_at do
      {:error, :already_confirmed}
    else
      RealTime.Person.RelationshipNotifier.broadcast_create_relationship(
        relationship,
        sent_to_person,
        requesting_person
      )
    end
  end

  @doc """
  Confirms a relationship by the given token.

  If the token matches, the relationship is marked as confirmed
  and the token is deleted.
  """
  def confirm_relationship(sent_to_person, requesting_person, current_person, current_person_key) do
    with true <- sent_to_person.id == current_person.id,
         %Relationship{} = relationship <-
           find_unconfirmed_relationship_match(requesting_person.id, current_person),
         {:ok, %{relationship: relationship}} <-
           Repo.transaction(confirm_relationship_multi(relationship)),
         {:ok, relationship} <-
           register_accepting_relationship(
             relationship,
             requesting_person,
             current_person,
             current_person_key
           ) do
      create_shared_person_avatars(relationship)
      create_shared_relation_avatars(relationship)
      RealTime.Person.Relationship.broadcast_save_relationship(relationship)

      {:ok, relationship}
    else
      _ ->
        :error
    end
  end

  defp confirm_relationship_multi(relationship) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:relationship, Relationship.confirm_changeset(relationship))
  end

  @doc """
  Returns the list of relationships for the current person.

  ## Examples

      iex> list_relationships(current_person)
      [%Relationship{}, ...]

  """
  def list_relationships(current_person) do
    preloads = [:relationship_type, :shared_portals]

    unless is_nil(current_person) do
      Repo.all(
        from r in Relationship,
          where: r.person_id == ^current_person.id,
          or_where: r.relation_id == ^current_person.id,
          where: not is_nil(r.confirmed_at),
          preload: ^preloads
      )
    end
  end

  @doc """
  Returns the relationships where the `current_person`
  is the `person` side of the relationship.

  This is to be used for downloading data.
  """
  def safe_download_list_person_relationships(current_person) when is_struct(current_person) do
    unless is_nil(current_person) do
      preloads = [:relationship_type]

      Repo.all(
        from r in Relationship,
          where: r.person_id == ^current_person.id,
          preload: ^preloads
      )
    end
  end

  @doc """
  Returns the relationships where the `current_person`
  is the `relation` side of the relationship.

  This is to be used for downloading data.
  """
  def safe_download_list_relation_relationships(current_person) when is_struct(current_person) do
    unless is_nil(current_person) do
      preloads = [:relationship_type]

      Repo.all(
        from r in Relationship,
          where: r.relation_id == ^current_person.id,
          preload: ^preloads
      )
    end
  end

  @doc """
  Returns the list of pending relationships for the current person.
  This returns all sides of the relationship (i.e. agnostic to who
  requested the relationship).

  ## Examples

      iex> list_relationships(current_person)
      [%Relationship{}, ...]

  """
  def list_unsafe_pending_relationships(current_person) do
    preloads = [:relationship_type, :shared_memories]

    unless is_nil(current_person) do
      Repo.all(
        from r in Relationship,
          where: r.person_id == ^current_person.id,
          or_where: r.relation_id == ^current_person.id,
          where: is_nil(r.confirmed_at),
          preload: ^preloads
      )
    end
  end

  @doc """
  Returns the list of pending relationships for the current person.
  This returns all pending relationships where current person did
  not request the relationship.

  This is what we typically use in the application. We do not want
  to reveal pending relationships that the current person has
  requested, for privacy.

  ## Examples

      iex> list_relationships(current_person)
      [%Relationship{}, ...]

  """
  def list_pending_relationships(current_person) do
    preloads = [:relationship_type, :shared_memories]

    unless is_nil(current_person) do
      Repo.all(
        from r in Relationship,
          where: r.relation_id == ^current_person.id,
          where: r.person_id != ^current_person.id,
          where: is_nil(r.confirmed_at),
          preload: ^preloads
      )
    end
  end

  def build_relationships_subquery(current_person) do
    query =
      from r in Relationship,
        where: r.person_id == ^current_person.id,
        or_where: r.relation_id == ^current_person.id,
        where: not is_nil(r.confirmed_at)

    query
  end

  @doc """
  Returns the list of relationships for the current person
  by the relationship name.
  """
  def list_relationships(current_person, name) do
    Repo.all(
      from r in Relationship,
        join: rt in "relationship_types",
        where: r.person_id == ^current_person.id or r.relation_id == ^current_person.id,
        where: not is_nil(r.confirmed_at),
        where: rt.name_hash == ^name,
        preload: [:relationship_type]
    )
  end

  @doc """
  Takes a `Relationship` and preloads the `RelationshipType`.
  """
  def preload_relationship_type(relationship) do
    Repo.one(from r in Relationship, where: r.id == ^relationship.id, preload: :relationship_type)
  end

  @doc """
  Takes a %Person{} and current_person and returns the %Relationship{} with the %RelationshipType{}.
  """
  def get_people_relationship_type(current_person, relation)
      when is_struct(current_person) and is_struct(relation) do
    Repo.one(
      from r in Relationship,
        join: rt in RelationshipType,
        on: rt.id == r.relationship_type_id,
        where: r.person_id == ^current_person.id and r.relation_id == ^relation.id,
        or_where: r.person_id == ^relation.id and r.relation_id == ^current_person.id,
        select: r,
        preload: [:relationship_type]
    )
  end

  def get_people_relationship_type(current_person, relation_id)
      when is_struct(current_person) and is_binary(relation_id) do
    Repo.one(
      from r in Relationship,
        join: rt in RelationshipType,
        on: rt.id == r.relationship_type_id,
        where: r.person_id == ^current_person.id and r.relation_id == ^relation_id,
        or_where: r.person_id == ^relation_id and r.relation_id == ^current_person.id,
        select: r,
        preload: [:relationship_type]
    )
  end

  @doc """
  This takes a relationship_id and returns both people. It
  calls out to the Accounts context at the end.

  If no relationship is found, it returns nil. If the people
  aren't found from the Accounts context, it raises an %Ecto.NoResultsError
  as that is not expected behavior.

  ## Example

      iex> get_people_from_relationship(123)
      {%Person{} = relation, %Person{} = person}

      iex> get_people_from_relationship(456)
      nil
  """
  def get_people_from_relationship(id) when is_binary(id) do
    relationship = Repo.get(Relationship, id)
    relation = Accounts.get_person!(relationship.relation_id)
    person = Accounts.get_person!(relationship.person_id)
    {relation, person}
  end

  @doc """
  Takes two people and returns the relationship.
  """
  def get_people_relationship!(current_person, person) do
    Repo.one!(
      from r in Relationship,
        where: ^current_person.id == r.person_id and ^person.id == r.relation_id,
        or_where: ^current_person.id == r.relation_id and ^person.id == r.person_id,
        preload: [:relationship_type]
    )
  end

  @doc """
  Takes two people and returns the relationship or nil.
  """
  def get_people_relationship(current_person, person)
      when is_struct(current_person) and is_struct(person) do
    Repo.one(
      from r in Relationship,
        where: ^current_person.id == r.person_id and ^person.id == r.relation_id,
        or_where: ^current_person.id == r.relation_id and ^person.id == r.person_id,
        preload: [:relationship_type]
    )
  end

  def get_people_relationship(current_person, relation_id)
      when is_struct(current_person) and is_binary(relation_id) do
    Repo.one(
      from r in Relationship,
        where: ^current_person.id == r.person_id and ^relation_id == r.relation_id,
        or_where: ^current_person.id == r.relation_id and ^relation_id == r.person_id,
        preload: [:relationship_type]
    )
  end

  @doc """
  Takes a person and another person's id and returns the relationship or nil.
  """
  def get_people_relationship_with_person_id(current_person, person_id) do
    Repo.one(
      from r in Relationship,
        where: ^current_person.id == r.person_id and ^person_id == r.relation_id,
        or_where: ^current_person.id == r.relation_id and ^person_id == r.person_id,
        preload: [:relationship_type]
    )
  end

  @doc """
  Takes a relationship_id and person_id and
  returns the %SharedAvatar{}. Returns nil
  if no %SharedAvatar{}.
  """
  def get_shared_avatar(relationship_id, person_id) do
    Repo.one(
      from sa in SharedAvatar,
        where: ^relationship_id == sa.relationship_id,
        where: ^person_id == sa.person_id,
        preload: [:person, :relationship]
    )
  end

  @doc """
  Gets all shared_avatars with a person_id. These are
  the avatars shared with a person from other people.
  """
  def get_all_shared_avatars(current_person) do
    Repo.all(
      from sa in SharedAvatar,
        where: ^current_person.id == sa.person_id,
        preload: [:person, :relationship]
    )
  end

  @doc """
  Gets all shared_avatars by a person_id. These are
  the avatars shared by a person to other people.
  """
  def get_all_shared_avatars_by_person(current_person) do
    Repo.all(
      from sa in SharedAvatar,
        where: ^current_person.id != sa.person_id,
        join: r in Relationship,
        on: sa.relationship_id == r.id,
        where: ^current_person.id == r.person_id or ^current_person.id == r.relation_id,
        preload: [:person, :relationship]
    )
  end

  @doc """
  Gets a SharedAvatar by id.
  """
  def get_shared_avatar_from_id!(id) do
    Repo.get!(SharedAvatar, id)
  end

  @doc """
  Gets a single relationship.

  Raises `Ecto.NoResultsError` if the Relationship does not exist.

  ## Examples

      iex> get_relationship!(123)
      %Relationship{}

      iex> get_relationship!(456)
      ** (Ecto.NoResultsError)

  """
  def get_relationship!(id), do: Repo.get!(Relationship, id)

  @doc """
  Gets a single relationship and preloads relationship_tokens.
  """
  def get_relationship_with_tokens(id) do
    Repo.one(
      from r in Relationship,
        where: r.id == ^id,
        preload: [:relationship_tokens]
    )
  end

  @doc """
  Finds a relationship match between the id and the current_person.
  """
  def find_relationship_match(id, current_person) do
    Repo.one(
      from r in Relationship,
        where:
          ((r.person_id == ^id and r.relation_id == ^current_person.id) or
             (r.person_id == ^current_person.id and r.relation_id == ^id)) and
            not is_nil(r.confirmed_at)
    )
  end

  @doc """
  Finds an unconfirmed relationship match between the id and the current_person.
  The id is the requesting person and so should be the person_id on the relationship.
  """
  def find_unconfirmed_relationship_match(id, current_person) do
    Repo.one(
      from r in Relationship,
        where: r.person_id == ^id and r.relation_id == ^current_person.id,
        where: is_nil(r.confirmed_at)
    )
  end

  @doc """
  Checks if two people are in a relationship and returns
  true or false.
  """
  def has_a_relationship?(person, current_person) do
    query =
      Repo.one(
        from r in Relationship,
          where: r.person_id == ^person.id and r.relation_id == ^current_person.id,
          or_where: r.relation_id == ^person.id and r.person_id == ^current_person.id
      )

    case query do
      %Relationship{} ->
        true

      nil ->
        false
    end
  end

  @doc """
  Checks if the current_person is in a relationship. Returns
  `nil` if the current_person is not in the relationship or relationship
  does not exist.

  Returns `nil` if guard checks fail.
  """
  def person_in_relationship?(current_person, relationship_id)
      when is_struct(current_person) and is_binary(relationship_id) do
    query =
      Repo.one(
        from r in Relationship,
          where: r.id == ^relationship_id and r.person_id == ^current_person.id,
          or_where: r.id == ^relationship_id and r.relation_id == ^current_person.id
      )

    case query do
      %Relationship{} ->
        true

      nil ->
        nil
    end
  end

  @doc """
  Finds a pending relationship between two people, using
  the `id` for one person and the current_person for the other.

  Note: the id is the `%Person{id: id}` from the other side of relationship,
  relative to the current_person.
  """
  def find_relationship_pending(id, current_person) do
    Repo.one(
      from r in Relationship,
        where:
          ((r.person_id == ^id and r.relation_id == ^current_person.id) or
             (r.person_id == ^current_person.id and r.relation_id == ^id)) and
            is_nil(r.confirmed_at)
    )
  end

  @doc """
  Returns true if a relationship exists where the id matches either the person_id or relation_id.

  ## Examples

    iex> exists_a_relationship?(123)
    true

    iex> exists_a_relationship?(456)
    false
  """
  def exists_a_relationship?(id) do
    query =
      from r in Relationship,
        where: (r.person_id == ^id or r.relation_id == ^id) and not is_nil(r.confirmed_at)

    Repo.exists?(query)
  end

  @doc """
  Updates a relationship.

  ## Examples

      iex> update_relationship(relationship, %{field: new_value})
      {:ok, %Relationship{}}

      iex> update_relationship(relationship, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_relationship(%Relationship{} = relationship, attrs) do
    relationship
    |> Relationship.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a relationship's controls. Currently
  only accepts `:can_download_memories?`.
  """
  def update_relationship_controls(%Relationship{} = relationship, attrs \\ %{}) do
    relationship
    |> Relationship.controls_changeset(attrs)
    |> Repo.update()
    |> RealTime.Person.Relationship.broadcast_update_relationship()
  end

  @doc """
  Deletes a relationship.

  ## Examples

      iex> delete_relationship(relationship)
      {:ok, %Relationship{}}

      iex> delete_relationship(relationship)
      {:error, %Ecto.Changeset{}}

  """
  def delete_relationship(%Relationship{} = relationship) do
    Repo.delete(relationship)
  end

  @doc """
  Delets a SharedAvatar.
  """
  def delete_shared_avatar(%SharedAvatar{} = shared_avatar) do
    Repo.delete(shared_avatar)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking relationship changes.

  ## Examples

      iex> change_relationship(relationship)
      %Ecto.Changeset{data: %Relationship{}}

  """
  def change_relationship(%Relationship{} = relationship, attrs \\ %{}) do
    Relationship.changeset(relationship, attrs)
  end

  @doc """
  Creates a relationship_type.
  """
  def create_relationship_type!(name) do
    Repo.insert!(%RelationshipType{name: name, name_hash: name}, on_conflict: :nothing)
  end

  @doc """
  List the relationship_types in alphabetical order.
  """
  def list_alphabetical_relationship_types do
    relationship_types =
      RelationshipType
      |> Repo.all()

    unless relationship_types == [] or nil do
      relationship_types =
        relationship_types
        |> Enum.sort(&(&1.name <= &2.name))

      relationship_types
    end
  end
end
