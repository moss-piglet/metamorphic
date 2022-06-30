defmodule Metamorphic.Announcements do
  @moduledoc """
  The Announcements context.
  """
  import Ecto.Query, warn: false

  alias Metamorphic.Repo
  alias Metamorphic.Announcements.Announcement
  alias MetamorphicWeb.RealTime

  ## Database getters

  @doc """
  Gets a single announcement.

  Raises `Ecto.NoResultsError` if the RoadmapFeature does not exist.

  ## Examples

      iex> get_announcement!(123)
      %RoadmapFeature{}

      iex> get_announcement!(456)
      ** (Ecto.NoResultsError)

  """
  def get_announcement!(id), do: Repo.get!(Announcement, id)

  @doc """
  Lists all announcements.

  Returns `nil` if there are no announcements or current_person.

  ## Examples

      iex> safe_list_announcements(current_person)
      [%Announcement{}, ...]

      iex> safe_list_announcements(current_person)
      nil
  """
  def safe_list_announcements(current_person) when is_struct(current_person) do
    Repo.all(
      from a in Announcement,
        order_by: [desc: a.inserted_at]
    )
  end

  @doc """
  Returns the latest announcement inserted
  into the DB.
  """
  def safe_get_current_announcement(current_person) when is_struct(current_person) do
    announcements =
      Repo.all(
        from a in Announcement,
          order_by: [desc: a.inserted_at]
      )

    announcement = List.first(announcements)
    announcement
  end

  ## Database writers

  @doc """
  Creates a new `Announcement{}`.
  """
  def create_announcement(attrs \\ %{}, current_person) when is_struct(current_person) do
    if current_person.privileges === :admin do
      %Announcement{}
      |> Announcement.changeset(attrs)
      |> Repo.insert()
      |> RealTime.Admin.Announcement.broadcast_save_announcement()
    end
  end

  @doc """
  Deletes a `%Announcement{}` from an admin. Checks to
  ensure that the current_person has the `:admin` privilege.

  Then, broadcasts the deleted_announcement to everyone
  connected to the `people:announcements` and
  `admin:announcements` topics.

  Returns `nil` otherwise.
  """
  def safe_delete_announcement(%Announcement{} = announcement, current_person)
      when is_struct(announcement) and is_struct(current_person) do
    if current_person.privileges === :admin do
      announcement
      |> Repo.delete()
      |> RealTime.Admin.Announcement.broadcast_delete_announcement()
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking announcement changes.

  ## Examples

      iex> change_announcement(announcement)
      %Ecto.Changeset{data: %Announcement{}}
  """
  def change_announcement(%Announcement{} = announcement, attrs \\ %{}) do
    Announcement.changeset(announcement, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking announcement
  update changes.

  ## Examples

      iex> update_announcement(announcement)
      %Ecto.Changeset{data: %Announcement{}}
  """
  def update_announcement(%Announcement{} = announcement, attrs \\ %{}) do
    Announcement.admin_update_changeset(announcement, attrs)
  end
end
