defmodule Metamorphic.InvitationsTest do
  use Metamorphic.DataCase

  import Metamorphic.InvitationsFixtures

  alias Metamorphic.Invitations

  describe "invitations" do
    alias Metamorphic.Invitations.Invite

    @valid_attrs %{email: "email#{System.unique_integer()}@example.com"}
    @update_attrs %{}
    @invalid_attrs %{email: "notanemail"}

    test "list_invitations/0 returns all invitations and email is hashed in database" do
      invite = invite_fixture()

      assert [invite] != Invitations.list_invitations()
      assert is_list(Invitations.list_invitations())
      assert [] != Invitations.list_invitations()
    end

    test "get_invite!/1 returns the invite with given id and email is hashed in database" do
      invite = invite_fixture()
      invite_with_given_id = Invitations.get_invite!(invite.id)

      assert invite != Invitations.get_invite!(invite.id)
      assert invite.id == invite_with_given_id.id
      assert invite.email == invite_with_given_id.email
    end

    test "create_invite/1 with valid data creates an invite" do
      assert {:ok, %Invite{}} = Invitations.create_invite(@valid_attrs)
    end

    test "create_invite/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Invitations.create_invite(@invalid_attrs)
    end

    test "create_invite/1 with valid data creates an invite only if email is unique" do
      assert {:ok, %Invite{}} = Invitations.create_invite(@valid_attrs)
      assert {:error, %Ecto.Changeset{}} = Invitations.create_invite(@valid_attrs)
    end

    test "update_invite/2 with valid data updates the invite" do
      invite = invite_fixture()

      assert {:ok, %Invite{}} = Invitations.update_invite(invite, @update_attrs)
    end

    test "update_invite/2 with invalid data returns error changeset and email is hashed in database" do
      invite = invite_fixture()
      invite_with_given_id = Invitations.get_invite!(invite.id)

      assert {:error, %Ecto.Changeset{}} = Invitations.update_invite(invite, @invalid_attrs)
      assert invite != Invitations.get_invite!(invite.id)
      assert invite.id == invite_with_given_id.id
      assert invite.email == invite_with_given_id.email
    end

    test "delete_invite/1 deletes the invite" do
      invite = invite_fixture()
      assert {:ok, %Invite{}} = Invitations.delete_invite(invite)
      assert_raise Ecto.NoResultsError, fn -> Invitations.get_invite!(invite.id) end
    end

    test "change_invite/1 returns a invite changeset" do
      invite = invite_fixture()
      assert %Ecto.Changeset{} = Invitations.change_invite(invite)
    end

    test "does not generate invite codes if the invite email has not been confirmed" do
      invite = invite_fixture(@valid_attrs, confirmed: false)

      assert invite.codes == nil
    end
  end
end
