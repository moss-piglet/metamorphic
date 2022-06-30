defmodule MetamorphicWeb.RealTime.Person.RoadmapFeatureVote do
  @moduledoc """
  RoadmapFeatureVote PubSub module for people to
  broadcast feature votes.
  """

  @admin_topic "admin:roadmap_feature_votes"
  @people_topic "people:roadmap_feature_votes"

  def subscribe(current_person) do
    if current_person.privileges === :admin do
      Phoenix.PubSub.subscribe(MetamorphicWeb.PubSub, @admin_topic)
    else
      Phoenix.PubSub.subscribe(MetamorphicWeb.PubSub, @people_topic)
    end
  end

  # Broadcasts the new roadmap feature from the approved request.
  # We broadcast to the `@people_topic` as we want all connected
  # people to receive the udpated roadmap_features list.
  def broadcast_save_roadmap_feature_vote({:ok, roadmap_feature_vote}) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @admin_topic,
      {:save_roadmap_feature_vote, roadmap_feature_vote}
    )

    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @people_topic,
      {:save_roadmap_feature_vote, roadmap_feature_vote}
    )

    {:ok, roadmap_feature_vote}
  end

  def broadcast_save_roadmap_feature_vote({:error, roadmap_feature_vote}),
    do: roadmap_feature_vote

  def broadcast_delete_roadmap_feature_vote({:ok, roadmap_feature_vote}) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @admin_topic,
      {:delete_roadmap_feature_vote, roadmap_feature_vote}
    )

    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @people_topic,
      {:delete_roadmap_feature_vote, roadmap_feature_vote}
    )

    {:ok, roadmap_feature_vote}
  end

  def broadcast_delete_roadmap_feature_vote({:error, roadmap_feature_vote}),
    do: roadmap_feature_vote
end
