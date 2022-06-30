defmodule Metamorphic.RoadmapFeatures.RoadmapFeatureVote do
  @moduledoc """
  `RoadmapFeatureVote{}` schema for `RoadmapFeatures` context.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Metamorphic.Accounts.Person
  # alias Metamorphic.EctoEnums.RoadmapFeaturesEnum
  alias Metamorphic.RoadmapFeatures.RoadmapFeature
  # alias Metamorphic.Encrypted

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "roadmap_feature_votes" do
    belongs_to :person, Person, type: :binary_id
    belongs_to :roadmap_feature, RoadmapFeature, type: :binary_id

    timestamps()
  end

  def changeset(roadmap_feature_vote, attrs) do
    roadmap_feature_vote
    |> cast(attrs, [:person_id, :roadmap_feature_id])
    |> validate_required([:person_id, :roadmap_feature_id])
    |> unsafe_validate_unique([:person_id, :roadmap_feature_id], Metamorphic.Repo)
    |> unique_constraint([:person_id, :roadmap_feature_id],
      name: :roadmap_feature_votes_person_id_roadmap_feature_id_index
    )
  end
end
