defmodule MetamorphicWeb.RealTime.Admin.RoadmapFeature do
  @moduledoc """
  RoadmapFeature PubSub module for admins to update
  people whenever they update a feature on the roadmap.
  """

  @admin_topic "admin:roadmap_features"
  @people_topic "people:roadmap_features"

  def subscribe(current_person) do
    if current_person.privileges === :admin do
      Phoenix.PubSub.subscribe(MetamorphicWeb.PubSub, @admin_topic)
    else
      Phoenix.PubSub.subscribe(MetamorphicWeb.PubSub, @people_topic)
    end
  end

  def broadcast_save_roadmap_feature({:ok, roadmap_feature}) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @admin_topic,
      {:save_roadmap_feature, roadmap_feature}
    )

    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @people_topic,
      {:save_roadmap_feature, roadmap_feature}
    )

    {:ok, roadmap_feature}
  end

  def broadcast_save_roadmap_feature(roadmap_feature), do: roadmap_feature

  def broadcast_update_roadmap_feature({:ok, roadmap_feature}) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @admin_topic,
      {:update_roadmap_feature, roadmap_feature}
    )

    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @people_topic,
      {:update_roadmap_feature, roadmap_feature}
    )

    {:ok, roadmap_feature}
  end

  def broadcast_update_roadmap_feature(roadmap_feature), do: roadmap_feature

  def broadcast_delete_roadmap_feature({:ok, roadmap_feature}) do
    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @admin_topic,
      {:delete_roadmap_feature, roadmap_feature}
    )

    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @people_topic,
      {:delete_roadmap_feature, roadmap_feature}
    )

    {:ok, roadmap_feature}
  end

  def broadcast_delete_roadmap_feature(roadmap_feature), do: roadmap_feature
end
