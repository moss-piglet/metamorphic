defmodule Metamorphic.ConstructorFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Metamorphic.Constructor` context.
  """
  def valid_portal_name, do: "Test Portal #{System.unique_integer([:positive])}"
  def unique_portal_slug, do: "Test Portal Slug-#{System.unique_integer([:positive])}"

  def portal_fixture(attrs \\ %{}) do
    {:ok, portal} =
      attrs
      |> Enum.into(%{
        name: valid_portal_name(),
        slug: unique_portal_slug(),
        person_id: attrs["id"]
      })
      |> Metamorphic.Constructor.create_portal()

    portal
  end
end
