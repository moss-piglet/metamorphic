defmodule Metamorphic.RelationshipsTest do
  use Metamorphic.DataCase

  alias Metamorphic.Relationships
  import Metamorphic.RelationshipsFixtures
  alias Metamorphic.Relationships.{Relationship, RelationshipToken}

  describe "relationships" do
    alias Metamorphic.Relationships.Relationship

    @valid_attrs %{is_family: true, is_friend: true, is_romantic: true}
    @update_attrs %{is_family: false, is_friend: false, is_romantic: false}
    @invalid_attrs %{is_family: nil, is_friend: nil, is_romantic: nil}

    def relationship_fixture(attrs \\ %{}) do
      {:ok, relationship} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Relationships.create_relationship()

      relationship
    end

    test "list_relationships/0 returns all relationships" do
      relationship = relationship_fixture()
      assert Relationships.list_relationships() == [relationship]
    end

    test "get_relationship!/1 returns the relationship with given id" do
      relationship = relationship_fixture()
      assert Relationships.get_relationship!(relationship.id) == relationship
    end

    test "create_relationship/1 with valid data creates a relationship" do
      assert {:ok, %Relationship{} = relationship} =
               Relationships.create_relationship(@valid_attrs)

      assert relationship.is_family == true
      assert relationship.is_friend == true
      assert relationship.is_romantic == true
    end

    test "create_relationship/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Relationships.create_relationship(@invalid_attrs)
    end

    test "update_relationship/2 with valid data updates the relationship" do
      relationship = relationship_fixture()

      assert {:ok, %Relationship{} = relationship} =
               Relationships.update_relationship(relationship, @update_attrs)

      assert relationship.is_family == false
      assert relationship.is_friend == false
      assert relationship.is_romantic == false
    end

    test "update_relationship/2 with invalid data returns error changeset" do
      relationship = relationship_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Relationships.update_relationship(relationship, @invalid_attrs)

      assert relationship == Relationships.get_relationship!(relationship.id)
    end

    test "delete_relationship/1 deletes the relationship" do
      relationship = relationship_fixture()
      assert {:ok, %Relationship{}} = Relationships.delete_relationship(relationship)
      assert_raise Ecto.NoResultsError, fn -> Relationships.get_relationship!(relationship.id) end
    end

    test "change_relationship/1 returns a relationship changeset" do
      relationship = relationship_fixture()
      assert %Ecto.Changeset{} = Relationships.change_relationship(relationship)
    end
  end
end
