defmodule Metamorphic.Constructor do
  @moduledoc """
  The Constructor context.
  """

  import Ecto.Query, warn: false

  alias Metamorphic.Repo
  alias Metamorphic.Constructor.{Portal, SharedPortal}
  alias Metamorphic.Encrypted
  alias Metamorphic.Relationships

  alias MetamorphicWeb.RealTime

  @doc """
  Gets a single portal using the slug.
  """
  def get_portal(slug) when is_binary(slug) do
    from(portal in Portal, where: portal.slug_hash == ^slug)
    |> Repo.one()
  end

  @doc """
  Gets a single portal or shared_portal using the slug and current_person.
  """
  def safe_get_portal_or_shared_portal(slug, current_person)
      when is_binary(slug) and is_struct(current_person) do
    portal =
      Repo.one(
        from p in Portal,
          where: p.slug_hash == ^slug,
          where: p.person_id == ^current_person.id
      )

    case portal do
      nil ->
        shared_portal =
          Repo.one(
            from sp in SharedPortal,
              where: sp.slug_hash == ^slug,
              where: sp.person_id == ^current_person.id
          )

        shared_portal

      %Portal{} = portal ->
        portal
    end
  end

  @doc """
  Returns the list of portals.

  ## Examples

      iex> list_portals())
      [%Portal{}, ...]

  """
  def list_portals() do
    Repo.all(Portal)
  end

  @doc """
  Returns a list of the current_person's portals.
  """
  def safe_list_portals(current_person) when is_struct(current_person) do
    unless is_nil(current_person) do
      Repo.all(
        from p in Portal,
          where: p.person_id == ^current_person.id
      )
    end
  end

  @doc """
  Returns a list of the current_person's portals.

  This is used for downloading data.
  """
  def safe_download_list_portals(current_person) when is_struct(current_person) do
    unless is_nil(current_person) do
      Repo.all(
        from p in Portal,
          where: p.person_id == ^current_person.id
      )
    end
  end

  @doc """
  Returns the list of portals for the current person.

  ## Examples

      iex> list_portals(current_person, relationship)
      [%Portal{}, ...]

  """
  def list_portals(current_person) do
    preloads = [:shared_portals]

    Repo.all(
      from p in Portal,
        where: p.person_id == ^current_person.id,
        preload: ^preloads
    )
  end

  @doc """
  Returns the list of portals for the current person's relationships.

  ## Examples

      iex> list_relationship_portals(current_person)
      [%Portal{}, ...]

  """
  def list_relationship_portals(current_person) do
    relationship_query = Relationships.build_relationships_subquery(current_person)

    Repo.all(
      from p in Portal,
        where: p.person_id != ^current_person.id,
        join: person in assoc(p, :person),
        join: r in subquery(relationship_query),
        where: r.person_id == ^current_person.id and r.relation_id == p.person_id,
        or_where: r.relation_id == ^current_person.id and r.person_id == p.person_id,
        preload: [:person]
    )
  end

  @doc """
  Gets a single portal.

  Raises `Ecto.NoResultsError` if the Portal does not exist.

  ## Examples

      iex> get_portal!(123)
      %Portal{}

      iex> get_portal!(456)
      ** (Ecto.NoResultsError)

  """
  def get_portal!(id), do: Repo.get!(Portal, id)

  @doc """
  Gets the origin portal from a SharedPortal%{}.

  Returns `nil` if the Portal does not exist.

  ## Examples

      iex> get_origin_portal(%SharedPortal{...})
      %Portal{}

      iex> get_origin_portal(%SharedPortal{...})
      ** (Ecto.NoResultsError)

  """
  def get_origin_portal(shared_portal), do: Repo.get(Portal, shared_portal.portal_id)

  ## Shared Portals

  @doc """
  Gets a %SharedPortal{} by its id.
  """
  def get_shared_portal!(id), do: Repo.get!(SharedPortal, id)

  @doc """
  Gets a shared_portal by the person_id and portal_id.

  Raises `Ecto.NoResultsError` if the Portal does not exist.


  ## Examples

      iex> get_shared_portal!(123, 123)
      %SharedPortal{}

      iex> get_shared_portal!(456, 123)
      ** (Ecto.NoResultsError)
  """
  def get_shared_portal!(person_id, portal_id) do
    Repo.one!(
      from sp in SharedPortal,
        where: sp.person_id == ^person_id,
        where: sp.portal_id == ^portal_id
    )
  end

  @doc """
  Gets a shared_portal by the slug and current_person_id.
  """
  def get_shared_portal_by_slug_and_current_person_id(slug, current_person_id) do
    Repo.one(
      from sp in SharedPortal,
        where: sp.person_id == ^current_person_id,
        where: sp.slug_hash == ^slug
    )
  end

  @doc """
  Lists all of the shared_portals for the current_person.
  """
  def safe_list_shared_portals(current_person) do
    Repo.all(
      from sp in SharedPortal,
        where: sp.person_id == ^current_person.id
    )
  end

  @doc """
  Lists all of the shared_portals for the current_person where
  the current_person_id is the portal_origin_id.

  This essentially returns the list of shared portals created
  from the current_person's original portal (i.e. all the shared_portals
  that they are sharing with other people).
  """
  def safe_list_shared_origin_portals(current_person) do
    Repo.all(
      from sp in SharedPortal,
        where: sp.portal_origin_id == ^current_person.id,
        where: sp.person_id != ^current_person.id
    )
  end

  @doc """
  Creates a portal.

  ## Examples

      iex> create_portal(%{field: value})
      {:ok, %Portal{}}

      iex> create_portal(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_portal(attrs \\ %{}, current_person) do
    attrs =
      attrs
      |> Encrypted.Portals.New.prepare_encrypted_portal_fields(current_person)

    %Portal{}
    |> Portal.encrypted_changeset(attrs)
    |> Repo.insert()
    |> RealTime.Person.Portal.broadcast_create_portal(current_person.id)
  end

  @doc """
  Shares a Portal.
  """
  def share_portal(%SharedPortal{} = shared_portal, person_id, current_person_id, attrs \\ %{})
      when is_binary(person_id) and is_binary(current_person_id) do
    shared_portal
    |> SharedPortal.changeset(attrs)
    |> Repo.insert()
    |> RealTime.Person.SharedPortal.broadcast_create_shared_portal(person_id, current_person_id)
  end

  @doc """
  Updates a portal.

  ## Examples

      iex> update_portal(portal, %{field: new_value})
      {:ok, %Portal{}}

      iex> update_portal(portal, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_portal(%Portal{} = portal, attrs) do
    portal
    |> Portal.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a portal.

  ## Examples

      iex> delete_portal(portal)
      {:ok, %Portal{}}

      iex> delete_portal(portal)
      {:error, %Ecto.Changeset{}}

  """
  def delete_portal(%Portal{} = portal) do
    portal
    |> Repo.delete()
    |> RealTime.Person.Portal.broadcast_delete_portal()
  end

  @doc """
  Deletes a shared_portal. Uses the person_id
  to broadcast to the person no longer being
  shared with.

  We also use the current_person_id to update
  the current_person that initiated the action.
  """
  def delete_shared_portal(%SharedPortal{} = shared_portal, person_id, current_person_id)
      when is_binary(person_id) and is_struct(shared_portal) do
    shared_portal
    |> Repo.delete()
    |> RealTime.Person.SharedPortal.broadcast_delete_shared_portal(person_id, current_person_id)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking portal changes.

  ## Examples

      iex> change_portal(portal)
      %Ecto.Changeset{data: %Portal{}}

  """
  def change_portal(%Portal{} = portal, attrs \\ %{}) do
    Portal.changeset(portal, attrs)
  end
end
