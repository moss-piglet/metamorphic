defmodule Metamorphic.RoadmapFeatures do
  @moduledoc """
  The Roadmap Features context.

  Context for `%RoadmapFeature{}`, `%RoadmapFeatureRequest{}`,
  and `%RoadmapFeatureVote{}`.
  """
  import Ecto.Query, warn: false

  alias Metamorphic.Repo
  alias Metamorphic.RoadmapFeatures.{RoadmapFeature, RoadmapFeatureRequest, RoadmapFeatureVote}
  alias MetamorphicWeb.RealTime

  ## Database getters

  @doc """
  Preloads the votes association.
  Takes a `%RoadmapFeature{}`.
  """
  def preload_votes(roadmap_feature) when is_struct(roadmap_feature) do
    Repo.preload(roadmap_feature, [:roadmap_feature_votes])
  end

  @doc """
  Gets a single roadmap_feature.

  Raises `Ecto.NoResultsError` if the RoadmapFeature does not exist.

  ## Examples

      iex> get_roadmap_feature!(123)
      %RoadmapFeature{}

      iex> get_roadmap_feature!(456)
      ** (Ecto.NoResultsError)

  """
  def get_roadmap_feature!(id), do: Repo.get!(RoadmapFeature, id)

  @doc """
  Gets a single roadmap_feature_request.

  Raises `Ecto.NoResultsError` if the RoadmapFeatureRequest does not exist.

  ## Examples

      iex> get_roadmap_feature_request!(123)
      %RoadmapFeatureRequest{}

      iex> get_roadmap_feature_request!(456)
      ** (Ecto.NoResultsError)

  """
  def get_roadmap_feature_request!(id), do: Repo.get!(RoadmapFeatureRequest, id)

  @doc """
  Gets a single roadmap_feature_vote by feature_id and person_id.

  Returns `nil` if the RoadmapFeatureVote does not exist.

  ## Examples

      iex> get_roadmap_feature_vote_by_feature_and_person_ids!(123, 456)
      %RoadmapFeatureRequest{}

      iex> get_roadmap_feature_vote_by_feature_and_person_ids!(456, 789)
      nil

  """
  def get_roadmap_feature_vote_by_feature_and_person_ids!(feature_id, person_id)
      when is_binary(feature_id) and is_binary(person_id) do
    Repo.one(
      from r in RoadmapFeatureVote,
        where: r.roadmap_feature_id == ^feature_id,
        where: r.person_id == ^person_id
    )
  end

  def admin_safe_list_roadmap_feature_requests(current_person) when is_struct(current_person) do
    unless current_person.privileges != :admin do
      Repo.all(
        from r in RoadmapFeatureRequest,
          order_by: [desc: r.inserted_at]
      )
    end
  end

  def safe_list_roadmap_features(current_person) when is_struct(current_person) do
    preloads = [:roadmap_feature_votes]

    Repo.all(
      from r in RoadmapFeature,
        order_by: [desc: r.inserted_at],
        preload: ^preloads
    )
  end

  ## Database writers

  @doc """
  Creates a new `RoadmapFeatureRequest{}`.
  """
  def create_roadmap_feature_request(attrs \\ %{}, current_person)
      when is_struct(current_person) do
    %RoadmapFeatureRequest{}
    |> RoadmapFeatureRequest.changeset(attrs)
    |> Repo.insert()
    |> RealTime.Admin.RoadmapFeatureRequest.broadcast_save_roadmap_feature_request()
  end

  @doc """
  Creates a new `RoadmapFeature{}` from a
  feature_request that has been approved by
  an admin.
  """
  def create_roadmap_feature_from_approved_request(attrs \\ %{}, current_person)
      when is_struct(current_person) do
    unless current_person.privileges != :admin && not attrs["approved"] do
      %RoadmapFeature{}
      |> RoadmapFeature.request_approved_changeset(attrs)
      |> Repo.insert()
      |> RealTime.Admin.RoadmapFeatureRequest.broadcast_save_roadmap_feature_from_approved_request()
    end
  end

  @doc """
  Creates a new `RoadmapFeatureVote{}` from
  a person casting their vote.
  """
  def create_roadmap_feature_vote(attrs \\ %{}, current_person) when is_struct(current_person) do
    unless current_person.id != attrs.person_id do
      %RoadmapFeatureVote{}
      |> RoadmapFeatureVote.changeset(attrs)
      |> Repo.insert()
      |> RealTime.Person.RoadmapFeatureVote.broadcast_save_roadmap_feature_vote()
    end
  end

  @doc """
  Creates a new `RoadmapFeature{}` from
  an admin.
  """
  def admin_create_roadmap_feature(attrs \\ %{}, current_person) when is_struct(current_person) do
    unless current_person.privileges !== :admin do
      %RoadmapFeature{}
      |> RoadmapFeature.admin_new_changeset(attrs)
      |> Repo.insert()
      |> RealTime.Admin.RoadmapFeature.broadcast_save_roadmap_feature()
    end
  end

  @doc """
  Approves a `RoadmapFeatureRequest{}`. Requires
  an admin to approve.

  After approval, it calls respective functions to
  create a new feature request on the horizon,
  delete the feature_request, and broadcasts to the
  person_id associated with the feature_request that
  their request was approved.
  """
  def admin_approve_roadmap_feature_request(
        %RoadmapFeatureRequest{} = feature_request,
        attrs \\ %{},
        current_person
      )
      when is_struct(current_person) do
    unless current_person.privileges != :admin do
      feature_request
      |> RoadmapFeatureRequest.admin_approval_changeset(attrs)
      |> Repo.update()
      |> safe_delete_approved_roadmap_feature_request(current_person)
      |> build_attrs_and_maybe_create_roadmap_feature_from_person_request(current_person)
    end
  end

  @doc """
  Deletes `%RoadmapFeatureVote{}` by the current_person.
  """
  def safe_delete_roadmap_feature_vote(feature_vote, current_person)
      when is_struct(feature_vote) and is_struct(current_person) do
    unless feature_vote.person_id != current_person.id do
      feature_vote
      |> Repo.delete()
      |> RealTime.Person.RoadmapFeatureVote.broadcast_delete_roadmap_feature_vote()
    end
  end

  @doc """
  Updates a `%RoadmapFeature`. Checks to ensure that
  the current_person has the `:admin` privilege.

  Then, broadcasts the updated_feature to all connected
  people.

  Returns `nil` otherwise.
  """
  def safe_update_roadmap_feature(%RoadmapFeature{} = feature, attrs \\ %{}, current_person)
      when is_struct(feature) and is_struct(current_person) do
    unless current_person.privileges != :admin do
      feature
      |> RoadmapFeature.admin_update_changeset(attrs)
      |> Repo.update()
      |> RealTime.Admin.RoadmapFeature.broadcast_update_roadmap_feature()
    end
  end

  @doc """
  Deletes a `%RoadmapFeatureRequest` that has been
  rejected. Checks to ensure that the current_person
  has the `:admin` privilege.

  Then, broadcasts the deleted_roadmap_feature to the
  person who created it (to inform them that their
  feature was not accepted.)

  Returns `nil` otherwise.
  """
  def safe_delete_rejected_roadmap_feature_request(
        %RoadmapFeatureRequest{} = feature_request,
        current_person
      )
      when is_struct(feature_request) and is_struct(current_person) do
    unless current_person.privileges != :admin do
      feature_request
      |> Repo.delete()
      |> RealTime.Admin.RoadmapFeatureRequest.broadcast_delete_rejected_roadmap_feature_request(
        feature_request.person_id
      )
    end
  end

  @doc """
  Deletes a `%RoadmapFeatureRequest` that has been
  approved. Checks to ensure that the current_person
  has the `:admin` privilege.

  Then, broadcasts the deleted_roadmap_feature to the
  person who created it (to inform them that their
  feature was not accepted.)

  Returns `nil` otherwise.
  """
  def safe_delete_approved_roadmap_feature_request(
        {:ok, %RoadmapFeatureRequest{} = feature_request},
        current_person
      )
      when is_struct(feature_request) and is_struct(current_person) do
    unless current_person.privileges != :admin do
      feature_request
      |> Repo.delete()
      |> RealTime.Admin.RoadmapFeatureRequest.broadcast_delete_approved_roadmap_feature_request(
        feature_request.person_id
      )
    end
  end

  @doc """
  Deletes a `%RoadmapFeature` from an admin. Checks to
  ensure that the current_person has the `:admin` privilege.

  Then, broadcasts the deleted_roadmap_feature to everyone
  connected to the `people:roadmap_features` and
  `admin:roadmap_features` topics.

  Returns `nil` otherwise.
  """
  def safe_delete_roadmap_feature(%RoadmapFeature{} = feature, current_person)
      when is_struct(feature) and is_struct(current_person) do
    unless current_person.privileges != :admin do
      feature
      |> Repo.delete()
      |> RealTime.Admin.RoadmapFeature.broadcast_delete_roadmap_feature()
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking roadmap feature
  request changes.

  ## Examples

      iex> change_roadmap_feature_request(roadmap_feature_request)
      %Ecto.Changeset{data: %RoadmapFeatureRequest{}}
  """
  def change_roadmap_feature_request(
        %RoadmapFeatureRequest{} = roadmap_feature_request,
        attrs \\ %{}
      ) do
    RoadmapFeatureRequest.changeset(roadmap_feature_request, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking roadmap feature
  request rejection changes.

  ## Examples

      iex> reject_roadmap_feature_request(roadmap_feature_request)
      %Ecto.Changeset{data: %RoadmapFeatureRequest{}}
  """
  def reject_roadmap_feature_request(
        %RoadmapFeatureRequest{} = roadmap_feature_request,
        attrs \\ %{}
      ) do
    RoadmapFeatureRequest.admin_rejection_changeset(roadmap_feature_request, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking roadmap feature
  delete changes.

  ## Examples

      iex> delete_roadmap_feature(roadmap_feature)
      %Ecto.Changeset{data: %RoadmapFeature{}}
  """
  def delete_roadmap_feature(%RoadmapFeature{} = roadmap_feature, attrs \\ %{}) do
    RoadmapFeature.admin_delete_changeset(roadmap_feature, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking roadmap feature
  new changes.

  ## Examples

      iex> new_roadmap_feature(roadmap_feature)
      %Ecto.Changeset{data: %RoadmapFeature{}}
  """
  def new_roadmap_feature(%RoadmapFeature{} = roadmap_feature, attrs \\ %{}, current_person)
      when is_struct(current_person) do
    unless current_person.privileges != :admin do
      RoadmapFeature.admin_new_changeset(roadmap_feature, attrs)
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking roadmap feature
  update changes.

  ## Examples

      iex> update_roadmap_feature(roadmap_feature)
      %Ecto.Changeset{data: %RoadmapFeature{}}
  """
  def update_roadmap_feature(%RoadmapFeature{} = roadmap_feature, attrs \\ %{}) do
    RoadmapFeature.admin_update_changeset(roadmap_feature, attrs)
  end

  defp build_attrs_and_maybe_create_roadmap_feature_from_person_request(
         {:ok, {:ok, %RoadmapFeatureRequest{} = feature_request}},
         current_person
       )
       when is_struct(current_person) do
    feature_attrs = build_roadmap_feature_attrs_from_person_request(feature_request)

    roadmap_feature =
      maybe_create_roadmap_feature_from_person_request(feature_attrs, current_person)

    roadmap_feature
  end

  defp build_attrs_and_maybe_create_roadmap_feature_from_person_request(_, _), do: nil

  defp build_roadmap_feature_attrs_from_person_request(feature_request)
       when is_struct(feature_request) do
    feature_attrs =
      %{}
      |> Map.put(:name, feature_request.name)
      |> Map.put(:description, feature_request.description)
      |> Map.put(:approved, feature_request.approved)
      |> Map.put(:approved_by, feature_request.approved_by)

    feature_attrs
  end

  # We take the approved request and create a `%RoadmapFeature{}` from it.
  defp maybe_create_roadmap_feature_from_person_request(feature_attrs, current_person)
       when is_map(feature_attrs) and is_struct(current_person) do
    case create_roadmap_feature_from_approved_request(feature_attrs, current_person) do
      {:ok, %RoadmapFeature{} = roadmap_feature} ->
        {:ok, roadmap_feature}

      nil ->
        nil

      changeset ->
        changeset
    end
  end

  defp maybe_create_roadmap_feature_from_person_request(_, _), do: nil
end
