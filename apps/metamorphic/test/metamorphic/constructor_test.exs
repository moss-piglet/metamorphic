defmodule Metamorphic.ConstructorTest do
  use Metamorphic.DataCase

  import Metamorphic.ConstructorFixtures

  alias Metamorphic.Accounts.Person
  alias Metamorphic.Repo

  alias Metamorphic.Constructor
  alias Metamorphic.Constructor.Portal

  @update_attrs %{name: "some updated name", slug: "some updated slug"}
  @invalid_attrs %{name: nil, slug: nil, person_id: nil}

  @valid_person_attrs %{
    name: "Max Webb",
    pseudonym: "max",
    email: "max@example.com",
    password: "Testing Zoology Zooing Testology!",
    password_confirmation: "Testing Zoology Zooing Testology!",
    terms_of_use: true,
    role: :person
  }

  describe "portals" do
    setup do
      person = Repo.insert!(Person.registration_changeset(%Person{}, @valid_person_attrs))
      {:ok, person: person}
    end

    test "list_portals/0 returns all portals and slug is hashed in database", %{person: person} do
      portal = portal_fixture(%{person_id: person.id})

      assert [portal] != Constructor.list_portals()
      assert is_list(Constructor.list_portals())
      assert [] != Constructor.list_portals()
    end

    test "get_portal!/1 returns the portal with given id and slug is hashed in database", %{
      person: person
    } do
      portal = portal_fixture(%{person_id: person.id})
      portal_with_given_id = Constructor.get_portal!(portal.id)

      assert portal != Constructor.get_portal!(portal.id)
      assert portal.id == portal_with_given_id.id
      assert portal.name == portal_with_given_id.name
      assert portal.slug == portal_with_given_id.slug
    end

    test "create_portal/1 with valid data creates a portal", %{person: person} do
      assert {:ok, new_portal} =
               Constructor.create_portal(%{
                 person_id: person.id,
                 name: "another portal",
                 slug: "another slug"
               })

      assert new_portal.name == "another portal"
      assert new_portal.slug == "another-slug"
    end

    test "create_portal/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Constructor.create_portal(@invalid_attrs)
    end

    test "update_portal/2 with valid data updates the portal", %{person: person} do
      portal = portal_fixture(%{person_id: person.id})

      assert {:ok, %Portal{} = portal} = Constructor.update_portal(portal, @update_attrs)
      assert portal.name == "some updated name"
      assert portal.slug == "some-updated-slug"
    end

    test "update_portal/2 with invalid data returns error changeset and slug is hashed in database",
         %{person: person} do
      portal = portal_fixture(%{person_id: person.id})
      portal_with_given_id = Constructor.get_portal!(portal.id)

      assert {:error, %Ecto.Changeset{}} = Constructor.update_portal(portal, @invalid_attrs)
      assert portal != Constructor.get_portal!(portal.id)
      assert portal.id == portal_with_given_id.id
      assert portal.name == portal_with_given_id.name
      assert portal.slug == portal_with_given_id.slug
    end

    test "delete_portal/1 deletes the portal", %{person: person} do
      portal = portal_fixture(%{person_id: person.id})

      assert {:ok, %Portal{}} = Constructor.delete_portal(portal)
      assert_raise Ecto.NoResultsError, fn -> Constructor.get_portal!(portal.id) end
    end

    test "change_portal/1 returns a portal changeset", %{person: person} do
      portal = portal_fixture(%{person_id: person.id})

      assert %Ecto.Changeset{} = Constructor.change_portal(portal)
    end
  end
end
