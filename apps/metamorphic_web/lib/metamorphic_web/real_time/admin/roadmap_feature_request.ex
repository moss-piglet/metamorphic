defmodule MetamorphicWeb.RealTime.Admin.RoadmapFeatureRequest do
  @moduledoc """
  RoadmapFeatureRequest PubSub module for admins to
  subscribe to receive updates from people when they
  request a new feature.
  """

  @admin_topic "admin:roadmap_features"
  @person_topic "person:roadmap_feature_request:*"
  @people_topic "people:roadmap_features"

  def subscribe(current_person) do
    if current_person.privileges === :admin do
      Phoenix.PubSub.subscribe(MetamorphicWeb.PubSub, @admin_topic)
    else
      Phoenix.PubSub.subscribe(MetamorphicWeb.PubSub, @person_topic <> "#{current_person.id}")
      Phoenix.PubSub.subscribe(MetamorphicWeb.PubSub, @people_topic)
    end
  end

  def broadcast_update_roadmap_feature_request(roadmap_feature_request) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @admin_topic,
      {:update_roadmap_feature_request, roadmap_feature_request}
    )

    {:ok, roadmap_feature_request}
  end

  # Broadcasts the new roadmap feature from the approved request.
  # We broadcast to the `@people_topic` as we want all connected
  # people to receive the udpated roadmap_features list.
  def broadcast_save_roadmap_feature_from_approved_request({:ok, roadmap_feature}) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @admin_topic,
      {:save_roadmap_feature_from_approved_request, roadmap_feature}
    )

    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @people_topic,
      {:save_roadmap_feature_from_approved_request, roadmap_feature}
    )

    {:ok, roadmap_feature}
  end

  def broadcast_save_roadmap_feature_from_approved_request({:error, roadmap_feature}),
    do: roadmap_feature

  @doc """
  Broadcasts the `%RoadmapFeatureRequest{}` that
  was approved by the admin. We broadcast to both
  the admin and the current_person's id (to let
  them know their request was approved).
  """
  def broadcast_admin_approve_roadmap_feature_request({:ok, roadmap_feature_request}, person_id) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @admin_topic,
      {:admin_approve_roadmap_feature_request, roadmap_feature_request}
    )

    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @person_topic <> "#{person_id}",
      {:admin_approve_roadmap_feature_request, roadmap_feature_request}
    )

    {:ok, roadmap_feature_request}
  end

  def broadcast_admin_approve_roadmap_feature_request(roadmap_feature_request),
    do: roadmap_feature_request

  def broadcast_save_roadmap_feature_request(roadmap_feature_request) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @admin_topic,
      {:save_roadmap_feature_request, roadmap_feature_request}
    )

    {:ok, roadmap_feature_request}
  end

  def broadcast_delete_rejected_roadmap_feature_request(roadmap_feature_request, person_id) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @admin_topic,
      {:delete_rejected_roadmap_feature_request, roadmap_feature_request}
    )

    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @person_topic <> "#{person_id}",
      {:delete_rejected_roadmap_feature_request, roadmap_feature_request}
    )

    {:ok, roadmap_feature_request}
  end

  def broadcast_delete_approved_roadmap_feature_request(roadmap_feature_request, person_id) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @admin_topic,
      {:delete_approved_roadmap_feature_request, roadmap_feature_request}
    )

    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @person_topic <> "#{person_id}",
      {:delete_approved_roadmap_feature_request, roadmap_feature_request}
    )

    {:ok, roadmap_feature_request}
  end
end
