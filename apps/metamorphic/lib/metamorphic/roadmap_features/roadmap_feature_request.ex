defmodule Metamorphic.RoadmapFeatures.RoadmapFeatureRequest do
  @moduledoc """
  `RoadmapFeatureRequest{}` schema for `RoadmapFeatures` context.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Metamorphic.Accounts.Person
  alias Metamorphic.RoadmapFeatures.{RoadmapFeature, RoadmapFeatureRequest}
  alias Metamorphic.{Encrypted, Hashed}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "roadmap_feature_requests" do
    field :name, Encrypted.Binary, redact: true
    field :name_hash, Hashed.HMAC, redact: true
    field :description, Encrypted.Binary, redact: true
    field :approved, :boolean, default: false
    field :approved_by, {:map, Encrypted.Binary}, redact: true
    field :reason, Encrypted.Binary, redact: true

    belongs_to :person, Person, type: :binary_id

    timestamps()
  end

  def changeset(feature_request, attrs) do
    feature_request
    |> cast(attrs, [:person_id, :name, :description])
    |> validate_required([:person_id, :description])
    |> validate_name()
    |> validate_length(:description, min: 20, max: 500)
  end

  def admin_rejection_changeset(feature_request, attrs) do
    feature_request
    |> cast(attrs, [:reason])
    |> validate_required([:reason])
    |> validate_length(:reason, min: 20, max: 500)
  end

  def admin_approval_changeset(feature_request, attrs) do
    feature_request
    |> cast(attrs, [:approved, :approved_by])
  end

  defp validate_name(changeset) do
    changeset
    |> validate_required([:name])
    |> validate_length(:name, max: 250)
    |> add_name_hash()
    |> validate_name_hash()
  end

  defp add_name_hash(changeset) do
    if Map.has_key?(changeset.changes, :name) do
      changeset
      |> put_change(:name_hash, String.downcase(get_field(changeset, :name)))
    else
      changeset
    end
  end

  defp validate_name_hash(changeset) do
    request_changeset = changeset

    changeset
    |> unsafe_validate_unique([:name_hash], Metamorphic.Repo)
    |> unique_constraint(:name_hash)
    |> maybe_validate_roadmap_feature_name()
    |> convert_back_to_request_changeset(request_changeset)
  end

  # Only check against the roadmap feature if we
  # don't already have a matching feature_request name.
  defp maybe_validate_roadmap_feature_name(changeset) do
    if Keyword.has_key?(changeset.errors, :name_hash) do
      changeset
    else
      changeset
      |> RoadmapFeature.validate_name_hash_from_request()
    end
  end

  defp convert_back_to_request_changeset(feature_changeset, request_changeset) do
    if Keyword.has_key?(feature_changeset.errors, :name_hash) do
      request_changeset = request_changeset |> add_error(:name_hash, "has already been taken")
      request_changeset
    else
      request_changeset
    end
  end

  ## Cross-schema check

  # Only to be called from `Metamorphic.RoadmapFeatures.RoadmapFeature`.
  def validate_name_hash_from_feature(feature_changeset) do
    if get_change(feature_changeset, :name) do
      attrs = %{} |> Map.put("name", get_change(feature_changeset, :name))

      %RoadmapFeatureRequest{}
      |> cast(attrs, [:name])
      |> RoadmapFeature.safe_cross_schema_request_validate_name()
    else
      feature_changeset
    end
  end

  # This prevents endless loops.
  # Function is called from the `RoadmapFeature` schema.
  def safe_cross_schema_feature_validate_name(changeset) do
    changeset
    |> cross_schema_validate_name()
  end

  defp cross_schema_validate_name(changeset) do
    changeset
    |> validate_required([:name])
    |> validate_length(:name, max: 250)
    |> add_name_hash()
    |> unsafe_validate_unique([:name_hash], Metamorphic.Repo)
    |> unique_constraint(:name_hash)
  end
end
