defmodule Metamorphic.Memories do
  @moduledoc """
  The Memories context.
  """

  import Ecto.Query, warn: false

  alias Metamorphic.Repo
  alias Metamorphic.Accounts.Person
  alias Metamorphic.Memories.{Memory, SharedMemory}
  alias Metamorphic.Relationships

  alias MetamorphicWeb.RealTime

  @doc """
  Searches a person's memories by memory name.
  """
  def search_by_memory_name(name, current_person) do
    safe_list_memories(current_person)
    |> Enum.filter(&(&1.name_hash == name))
  end

  @doc """
  Returns a list of the current_person's
  Memories.
  """
  def safe_list_memories(current_person) when is_struct(current_person) do
    unless is_nil(current_person) do
      Repo.all(
        from m in Memory,
          where: m.person_id == ^current_person.id,
          order_by: [desc: m.inserted_at],
          preload: [:person, :shared_memories]
      )
    end
  end

  @doc """
  Paginate and sort a person's memories by current_person.
  Returns a list of memories matching the given `criteria`.

  ## Example Criteria

      [
        paginate: %{page: 2, per_page: 5},
        sort: %{sort_by: :item, sort_order: :asc}
      ]
  """
  def safe_list_memories(current_person, criteria) when is_list(criteria) do
    query =
      from(m in Memory,
        where: m.person_id == ^current_person.id,
        order_by: [desc: m.inserted_at],
        preload: [:person, :shared_memories]
      )

    Enum.reduce(criteria, query, fn
      {:paginate, %{page: page, per_page: per_page}}, query ->
        from q in query,
          offset: ^((page - 1) * per_page),
          limit: ^per_page

        # {:sort, %{sort_by: sort_by, sort_order: sort_order}}, query ->
        #  from q in query, order_by: [{^sort_order, ^sort_by}]
    end)
    |> Repo.all()
  end

  @doc """
  Returns a list of the current_person's memories.

  This is used for downloading data.
  """
  def safe_download_list_memories(current_person) when is_struct(current_person) do
    unless is_nil(current_person) do
      preloads = [:shared_memories]

      Repo.all(
        from m in Memory,
          where: m.person_id == ^current_person.id,
          preload: ^preloads
      )
    end
  end

  @doc """
  Gets a single memory using the name.
  """
  def get_memory(name) when is_binary(name) do
    from(memory in Memory, where: memory.name_hash == ^name)
    |> Repo.one()
  end

  @doc """
  Returns the list of memories.

  ## Examples

      iex> list_memories())
      [%Memory{}, ...]

  """
  def list_memories() do
    Repo.all(Memory)
  end

  @doc """
  Returns the list of shared_memories shared with the current person.
  """
  def safe_list_shared_with_memories(current_person) do
    unless is_nil(current_person) do
      Repo.all(
        from sm in SharedMemory,
          where: sm.person_id == ^current_person.id,
          order_by: [desc: sm.inserted_at],
          preload: [:memory, :person]
      )
    end
  end

  @doc """
  Paginate and sort a person's shared_with_memories by current_person.
  Returns a list of shared_memories matching the given `criteria`.

  ## Example Criteria

      [
        paginate: %{shared_page: 2, shared_per_page: 5},
        sort: %{sort_by: :item, sort_order: :asc}
      ]
  """
  def safe_list_shared_with_memories(current_person, criteria) when is_list(criteria) do
    unless is_nil(current_person) do
      query =
        from(sm in SharedMemory,
          where: sm.person_id == ^current_person.id,
          order_by: [desc: sm.inserted_at],
          preload: [:memory, :person]
        )

      Enum.reduce(criteria, query, fn
        {:paginate, %{shared_page: page, shared_per_page: per_page}}, query ->
          from q in query,
            offset: ^((page - 1) * per_page),
            limit: ^per_page

          # {:sort, %{sort_by: sort_by, sort_order: sort_order}}, query ->
          #  from q in query, order_by: [{^sort_order, ^sort_by}]
      end)
      |> Repo.all()
    end
  end

  @doc """
  Returns the combined list of favorited memories and shared_memories
  for the current person.
  """
  def safe_list_favorite_memories(current_person) do
    unless is_nil(current_person) do
      shared_favorites =
        Repo.all(
          from sm in SharedMemory,
            where: sm.person_id == ^current_person.id,
            where: sm.favorite == true,
            order_by: [desc: sm.inserted_at],
            preload: [:memory, :person, :relationship]
        )

      own_favorites =
        Repo.all(
          from m in Memory,
            where: m.person_id == ^current_person.id,
            where: m.favorite == true,
            order_by: [desc: m.inserted_at],
            preload: [:person, :shared_memories]
        )

      favorites = List.flatten([shared_favorites, own_favorites])

      favorites
    end
  end

  @doc """
  Paginate and sort a person's favorite_memories by current_person.
  Returns a list of favorite_memories matching the given `criteria`.

  ## Example Criteria

      [
        paginate: %{favorite_page: 2, favorite_per_page: 5},
        sort: %{sort_by: :item, sort_order: :asc}
      ]
  """
  def safe_list_favorite_memories(current_person, criteria) when is_list(criteria) do
    unless is_nil(current_person) do
      query_shared =
        from(sm in SharedMemory,
          where: sm.person_id == ^current_person.id,
          where: sm.favorite == true,
          order_by: [desc: sm.inserted_at],
          preload: [:memory, :person, :relationship]
        )

      shared_favorites =
        Enum.reduce(criteria, query_shared, fn
          {:paginate, %{favorite_page: page, favorite_per_page: per_page}}, query ->
            from q in query,
              offset: ^((page - 1) * per_page),
              limit: ^per_page

            # {:sort, %{sort_by: sort_by, sort_order: sort_order}}, query ->
            #  from q in query, order_by: [{^sort_order, ^sort_by}]
        end)
        |> Repo.all()

      query_own =
        from(m in Memory,
          where: m.person_id == ^current_person.id,
          where: m.favorite == true,
          order_by: [desc: m.inserted_at],
          preload: [:person, :shared_memories]
        )

      favorites =
        Enum.reduce(criteria, query_own, fn
          {:paginate, %{favorite_page: page, favorite_per_page: per_page}}, query ->
            from q in query,
              offset: ^((page - 1) * per_page),
              limit: ^per_page

            # {:sort, %{sort_by: sort_by, sort_order: sort_order}}, query ->
            #  from q in query, order_by: [{^sort_order, ^sort_by}]
        end)
        |> Repo.all()

      favorites = List.flatten([shared_favorites, favorites])

      favorites
    end
  end

  @doc """
  Returns the list of hidden memories
  for the current person.
  """
  def list_hidden_memories(current_person) do
    unless is_nil(current_person) do
      Repo.all(
        from m in Memory,
          where: m.person_id == ^current_person.id,
          where: m.hidden == true,
          order_by: [desc: m.inserted_at],
          preload: [:person, :shared_memories]
      )
    end
  end

  @doc """
  Returns the list of hidden shared_memories
  for the current person.
  """
  def list_hidden_shared_memories(current_person) do
    unless is_nil(current_person) do
      Repo.all(
        from sm in SharedMemory,
          where: sm.person_id == ^current_person.id,
          where: sm.hidden == true,
          order_by: [desc: sm.inserted_at],
          preload: [:memory, :person, :relationship]
      )
    end
  end

  @doc """
  Returns a list of memories for the current_person's relationships.
  This is unsafe and should only be used as a step to getting the
  explicitly shared memories.

  ## Examples

      iex> list_relationship_memories(current_person)
      [%Memory{}, ...]

  """
  def list_unsafe_relationship_memories(current_person) do
    relationship_query = Relationships.build_relationships_subquery(current_person)

    Repo.all(
      from m in Memory,
        where: m.person_id != ^current_person.id,
        join: person in assoc(m, :person),
        join: r in subquery(relationship_query),
        where: r.person_id == ^current_person.id and r.relation_id == m.person_id,
        or_where: r.relation_id == ^current_person.id and r.person_id == m.person_id,
        preload: [:person]
    )
  end

  @doc """
  Gets a single memory.

  Raises `Ecto.NoResultsError` if the Memory does not exist.

  ## Examples

      iex> get_memory!(123)
      %Memory{}

      iex> get_memory!(456)
      ** (Ecto.NoResultsError)

  """
  def get_memory!(id), do: Repo.get!(Memory, id)

  @doc """
  Gets a single memory scoped to current_person.
  """
  def safe_get_memory(id, current_person) do
    Repo.one(
      from m in Memory,
        where: ^id == m.id,
        where: ^current_person.id == m.person_id,
        preload: [:person, :shared_memories]
    )
  end

  @doc """
  Gets a single shared_memory scoped to current_person.
  """
  def safe_get_shared_memory(id, current_person) do
    Repo.one(
      from sm in SharedMemory,
        where: ^id == sm.id,
        where: ^current_person.id == sm.person_id,
        preload: [:person, :memory, :relationship]
    )
  end

  @doc """
  Returns all the %Person{} structs that a given
  memory is shared with for the current person.
  Will return nil if it hasn't been shared.
  """
  def safe_get_all_shared_with_for_memory(id, current_person) do
    query =
      Repo.all(
        from sm in SharedMemory,
          join: memory in assoc(sm, :memory),
          on: memory.id == ^id,
          where: memory.person_id == ^current_person.id,
          select: sm.person_id
      )

    shared_query =
      from p in Person,
        where: p.id in ^query,
        select: p

    Repo.all(shared_query)
  end

  @doc """
  Returns all the %Person{} structs that a given
  memory is shared with. Will return nil
  if it hasn't been shared.
  """
  def get_shared_with_for_memory(id) do
    query =
      Repo.all(
        from sm in SharedMemory,
          join: memory in assoc(sm, :memory),
          on: memory.id == ^id,
          select: sm.person_id
      )

    shared_query =
      from p in Person,
        where: p.id in ^query,
        select: p

    Repo.all(shared_query)
  end

  @doc """
  Returns a single shared_memory.
  """
  def get_shared_memory!(id), do: Repo.get!(SharedMemory, id)

  @doc """
  Returns a single shared_memory or nil.
  """
  def get_shared_memory(id), do: Repo.get(SharedMemory, id)

  @doc """
  Returns a single shared_memory from
  a person's id and memory's id.
  """
  def get_shared_memory!(person_id, memory_id) do
    Repo.one!(
      from sm in SharedMemory,
        where: sm.person_id == ^person_id,
        where: sm.memory_id == ^memory_id
    )
  end

  @doc """
  Returns a single shared_memory or nil from
  a person's id and memory's id.

  This checks if the `person_id` of the shared_memory
  matches the `current_person.id`.
  """
  def get_shared_memory(person_id, memory_id, current_person_id)
      when person_id == current_person_id do
    Repo.one(
      from sm in SharedMemory,
        where: sm.person_id == ^person_id,
        where: sm.memory_id == ^memory_id
    )
  end

  @doc """
  Creates a memory.

  ## Examples

      iex> create_memory(%{field: value})
      {:ok, %Memory{}}

      iex> create_memory(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_memory(%Memory{} = memory, attrs \\ %{}, fun) do
    memory
    |> Memory.encrypted_changeset(attrs)
    |> Repo.insert()
    |> after_save(fun)
    |> RealTime.Person.Memory.broadcast_save_memory()
  end

  defp after_save({:ok, memory}, fun) do
    {:ok, _memory} = fun.(memory)
  end

  defp after_save(error, _fun), do: error

  @doc """
  Updates a memory.

  ## Examples

      iex> update_memory(memory, %{field: new_value})
      {:ok, %Memory{}}

      iex> update_memory(memory, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_memory(%Memory{} = memory, attrs \\ %{}, fun) do
    memory
    |> Memory.changeset(attrs)
    |> Repo.update()
    |> after_save(fun)
    |> RealTime.Person.Memory.broadcast_update_memory()
  end

  @doc """
  Updates a memory for favoriting.
  """
  def update_memory_favorite(%Memory{} = memory, attrs \\ %{}, current_person) do
    memory
    |> Memory.favorite_changeset(attrs)
    |> Repo.update()
    |> RealTime.Person.FavoriteMemory.broadcast_update_favorite_memory(current_person)
  end

  @doc """
  Updates a shared_memory.
  """
  def update_shared_memory(%SharedMemory{} = shared_memory, attrs \\ %{}, current_person) do
    shared_memory
    |> SharedMemory.favorite_changeset(attrs)
    |> Repo.update()
    |> RealTime.Person.FavoriteMemory.broadcast_update_shared_memory(current_person)
  end

  @doc """
  Updates a favorite shared_memory.
  This is a shared_memory that has already
  been favorited and is in the `:favorites` tab
  of the Memories index page.
  """
  def update_favorite_shared_memory(%SharedMemory{} = shared_memory, attrs \\ %{}, current_person) do
    shared_memory
    |> SharedMemory.favorite_changeset(attrs)
    |> Repo.update()
    |> RealTime.Person.FavoriteMemory.broadcast_update_favorite_shared_memory(current_person)
  end

  @doc """
  Updates a favorite memory.
  This is a memory that has already
  been favorited and is in the `:favorites` tab
  of the Memories index page.
  """
  def update_favorite_memory_after_favorite(%Memory{} = memory, attrs \\ %{}, current_person) do
    memory
    |> SharedMemory.favorite_changeset(attrs)
    |> Repo.update()
    |> RealTime.Person.FavoriteMemory.broadcast_update_favorite_memory_after_favorite(
      current_person
    )
  end

  @doc """
  Updates a memory for hiding using
  the hidden boolean.
  """
  def update_memory_hide(%Memory{} = memory, attrs \\ %{}, current_person) do
    memory
    |> Memory.hidden_changeset(attrs)
    |> Repo.update()
    |> RealTime.Person.HiddenMemory.broadcast_update_memory_hide(current_person)
  end

  @doc """
  Updates a hidden memory to reveal it.
  This is a memory that has already
  been hidden.
  """
  def update_memory_reveal(%Memory{} = memory, attrs \\ %{}, current_person) do
    memory
    |> Memory.hidden_changeset(attrs)
    |> Repo.update()
    |> RealTime.Person.HiddenMemory.broadcast_update_memory_reveal(current_person)
  end

  @doc """
  Updates a shared_memory for hiding using
  the hidden boolean.
  """
  def update_shared_memory_hide(%SharedMemory{} = shared_memory, attrs \\ %{}, current_person) do
    shared_memory
    |> SharedMemory.hidden_changeset(attrs)
    |> Repo.update()
    |> RealTime.Person.HiddenSharedMemory.broadcast_update_shared_memory_hide(current_person)
  end

  @doc """
  Updates a hidden shared_memory to reveal it.
  This is a shared_memory that has already
  been hidden.
  """
  def update_shared_memory_reveal(%SharedMemory{} = shared_memory, attrs \\ %{}, current_person) do
    shared_memory
    |> SharedMemory.hidden_changeset(attrs)
    |> Repo.update()
    |> RealTime.Person.HiddenSharedMemory.broadcast_update_shared_memory_reveal(current_person)
  end

  @doc """
  Shares a memory.
  """
  def share_memory(%SharedMemory{} = shared_memory, attrs \\ %{}) do
    shared_memory
    |> SharedMemory.changeset(attrs)
    |> Repo.insert()
    |> RealTime.Person.Memory.broadcast_share_memory()
  end

  @doc """
  Adds a description to a memory.
  """
  def add_memory_description(%Memory{} = memory, attrs \\ %{}) do
    memory
    |> Memory.description_changeset(attrs)
    |> Repo.update()
    |> RealTime.Person.Memory.broadcast_update_memory_description()
  end

  @doc """
  Deletes a memory.

  ## Examples

      iex> delete_memory(memory)
      {:ok, %Memory{}}

      iex> delete_memory(memory)
      {:error, %Ecto.Changeset{}}

  """
  def delete_memory(%Memory{} = memory) do
    memory =
      memory
      |> Repo.delete()
      |> RealTime.Person.Memory.broadcast_delete_memory()

    # File.rm("#{:code.priv_dir(:metamorphic_web)}" <> "/static/#{url}")

    memory
  end

  @doc """
  Deletes a shared_memory.
  """
  def delete_shared_memory(%SharedMemory{} = shared_memory) do
    shared_memory
    |> Repo.delete()
    |> RealTime.Person.Memory.broadcast_delete_shared_memory()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking memory changes.

  ## Examples

      iex> change_memory(memory)
      %Ecto.Changeset{data: %Memory{}}

  """
  def change_memory(%Memory{} = memory, attrs \\ %{}) do
    Memory.changeset(memory, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking memory description changes.

  ## Examples

      iex> change_memory(memory)
      %Ecto.Changeset{data: %Memory{}}

  """
  def change_memory_description(%Memory{} = memory, attrs \\ %{}) do
    Memory.description_changeset(memory, attrs)
  end
end
