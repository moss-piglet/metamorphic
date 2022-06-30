defmodule Metamorphic.RoadmapFeatures.RoadmapFeature do
  @moduledoc """
  `RoadmapFeature{}` schema for `RoadmapFeatures` context.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Metamorphic.Accounts
  alias Metamorphic.Accounts.Person
  alias Metamorphic.EctoEnums.RoadmapFeaturesEnum
  alias Metamorphic.RoadmapFeatures.{RoadmapFeature, RoadmapFeatureRequest, RoadmapFeatureVote}
  alias Metamorphic.{Encrypted, Hashed}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "roadmap_features" do
    field :name, Encrypted.Binary, redact: true
    field :name_hash, Hashed.HMAC, redact: true
    field :name_confirmation, :string, virtual: true
    field :description, Encrypted.Binary, redact: true
    field :approved, :boolean, default: false
    field :approved_by, {:map, Encrypted.Binary}, redact: true
    field :stages, RoadmapFeaturesEnum, default: :horizon, redact: true

    has_many :roadmap_feature_votes, RoadmapFeatureVote

    timestamps()
  end

  def changeset(feature, attrs) do
    feature
    |> cast(attrs, [:name, :description, :stages])
    |> validate_required([:name, :description, :stages])
    |> validate_length(:description, min: 20, max: 500)
  end

  def request_approved_changeset(feature, attrs) do
    feature
    |> cast(attrs, [:name, :description, :approved, :approved_by])
    |> validate_required([:description, :approved, :approved_by])
    |> validate_name()
    |> validate_length(:description, min: 20, max: 500)
  end

  def admin_update_changeset(feature, attrs) do
    feature
    |> cast(attrs, [:name, :description, :approved_by, :stages])
    |> validate_required([:name, :description, :approved_by, :stages])
    |> validate_name()
    |> validate_length(:description, min: 20, max: 500)
  end

  def admin_delete_changeset(feature, attrs) do
    feature
    |> cast(attrs, [:name])
    |> validate_confirmation(:name, message: "does not match name")
  end

  def admin_new_changeset(feature, attrs) do
    feature
    |> cast(attrs, [:name, :description, :stages, :approved, :approved_by])
    |> validate_required([:name, :description, :stages, :approved, :approved_by, :stages])
    |> validate_name()
    |> validate_length(:description, min: 20, max: 500)
    |> validate_is_admin?()
  end

  defp validate_is_admin?(changeset) do
    if Map.has_key?(changeset.changes, :approved_by) do
      if is_nil(Accounts.get_admin(changeset.changes.approved_by.id)) do
        changeset
        |> add_error(:approved_by, "invalid")
      else
        changeset
      end
    else
      changeset
    end
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
    feature_changeset = changeset

    changeset
    |> unsafe_validate_unique([:name_hash], Metamorphic.Repo)
    |> unique_constraint(:name_hash)
    |> maybe_validate_roadmap_feature_request_name()
    |> convert_back_to_feature_changeset(feature_changeset)
  end

  # Only check against the roadmap feature request if we
  # don't already have a matching feature name.
  defp maybe_validate_roadmap_feature_request_name(changeset) do
    if Keyword.has_key?(changeset.errors, :name_hash) do
      changeset
    else
      changeset
      |> RoadmapFeatureRequest.validate_name_hash_from_feature()
    end
  end

  defp convert_back_to_feature_changeset(request_changeset, feature_changeset) do
    if Keyword.has_key?(request_changeset.errors, :name_hash) do
      feature_changeset = feature_changeset |> add_error(:name_hash, "has already been taken")
      feature_changeset
    else
      feature_changeset
    end
  end

  ## Cross-schema check

  # Only to be called from `Metamorphic.RoadmapFeatures.RoadmapFeatureRquest`.
  def validate_name_hash_from_request(feature_request_changeset) do
    if get_change(feature_request_changeset, :name) do
      attrs = %{} |> Map.put("name", get_change(feature_request_changeset, :name))

      %RoadmapFeature{}
      |> cast(attrs, [:name])
      |> RoadmapFeatureRequest.safe_cross_schema_feature_validate_name()
    else
      feature_request_changeset
    end
  end

  # This prevents endless loops.
  # Function is called from the `RoadmapFeatureRequest` schema.
  def safe_cross_schema_request_validate_name(changeset) do
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
